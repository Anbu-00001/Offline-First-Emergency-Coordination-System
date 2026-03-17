package main

import (
	"log"
	"sync"
)

// GossipLog implements a causal message log for the OpenRescue P2P network.
//
// Day-18: Messages are only forwarded downstream (via outChan) once all their
// declared dependencies (PrevMsgIDs) are present in the log.
//
// Architecture:
//
//	GossipSub → PubSubManager.listenLoop → GossipLog.Receive()
//	                                              ↓ (when canApply)
//	                                         outChan → APIServer WebSocket clients
type GossipLog struct {
	mu sync.RWMutex

	// log stores all messages that have been fully applied (causally ready).
	// Key: MsgID → NetworkEnvelope
	log map[string]NetworkEnvelope

	// pending stores messages waiting for their dependencies to arrive.
	// Key: MsgID → NetworkEnvelope
	pending map[string]NetworkEnvelope

	// heads is the set of message IDs that have no known children.
	// Updated on every application. Used for future sync optimization.
	heads map[string]bool

	// outChan is the downstream channel where causally-ready messages are emitted.
	outChan chan<- NetworkEnvelope
}

// NewGossipLog creates and returns a new GossipLog backed by the given output channel.
func NewGossipLog(outChan chan<- NetworkEnvelope) *GossipLog {
	return &GossipLog{
		log:     make(map[string]NetworkEnvelope),
		pending: make(map[string]NetworkEnvelope),
		heads:   make(map[string]bool),
		outChan: outChan,
	}
}

// Receive processes an incoming message from the network.
//
// If all declared dependencies are already in the log, the message is applied
// immediately. Otherwise it is placed in the pending queue until its
// dependencies arrive.
func (gl *GossipLog) Receive(env NetworkEnvelope) {
	gl.mu.Lock()
	defer gl.mu.Unlock()

	log.Printf("[GossipLog] MESSAGE_RECEIVED: msg_id=%s msg_type=%s clock=%d deps=%v",
		env.MsgID, env.MsgType, env.Clock, env.PrevMsgIDs)

	// Skip if already known (extra safety beyond PubSub dedup)
	if _, exists := gl.log[env.MsgID]; exists {
		return
	}
	if _, exists := gl.pending[env.MsgID]; exists {
		return
	}

	if gl.canApplyLocked(env) {
		gl.applyLocked(env)
		// Re-check pending queue — newly applied message may unblock others
		gl.tryApplyPendingLocked()
	} else {
		gl.pending[env.MsgID] = env
		log.Printf("[GossipLog] MESSAGE_PENDING: msg_id=%s waiting for deps=%v",
			env.MsgID, env.PrevMsgIDs)
	}
}

// RecordSent records a locally-originated (sent) message directly into the log
// without sending it to outChan (it was already applied locally).
// This ensures that other nodes' messages depending on our messages can be applied.
func (gl *GossipLog) RecordSent(env NetworkEnvelope) {
	gl.mu.Lock()
	defer gl.mu.Unlock()

	if _, exists := gl.log[env.MsgID]; exists {
		return
	}

	gl.log[env.MsgID] = env
	gl.updateHeadsLocked(env)

	log.Printf("[GossipLog] SELF_RECORDED: msg_id=%s msg_type=%s clock=%d",
		env.MsgID, env.MsgType, env.Clock)

	// Unblock any pending messages that depended on this one
	gl.tryApplyPendingLocked()
}

// canApplyLocked checks whether all declared dependencies of env are present in the log.
// Must be called with gl.mu held.
func (gl *GossipLog) canApplyLocked(env NetworkEnvelope) bool {
	for _, depID := range env.PrevMsgIDs {
		if depID == "" {
			continue
		}
		if _, exists := gl.log[depID]; !exists {
			return false
		}
	}
	return true
}

// applyLocked moves a message from pending (or new) into the log and emits it downstream.
// Must be called with gl.mu held.
func (gl *GossipLog) applyLocked(env NetworkEnvelope) {
	// Move from pending if it was there
	delete(gl.pending, env.MsgID)

	// Store in the log
	gl.log[env.MsgID] = env

	// Update HEADS set
	gl.updateHeadsLocked(env)

	log.Printf("[GossipLog] MESSAGE_APPLIED: msg_id=%s msg_type=%s clock=%d",
		env.MsgID, env.MsgType, env.Clock)

	// Forward to downstream channel (non-blocking to avoid deadlock under lock)
	select {
	case gl.outChan <- env:
	default:
		log.Printf("[GossipLog] WARNING: outChan full, dropping msg_id=%s", env.MsgID)
	}
}

// tryApplyPendingLocked scans the pending queue and applies any messages whose
// dependencies are now satisfied. Repeats until no more messages can be applied.
// Must be called with gl.mu held.
func (gl *GossipLog) tryApplyPendingLocked() {
	for {
		applied := false
		for msgID, env := range gl.pending {
			if gl.canApplyLocked(env) {
				log.Printf("[GossipLog] DEPENDENCY_RESOLVED: msg_id=%s deps=%v now satisfied",
					msgID, env.PrevMsgIDs)
				gl.applyLocked(env)
				applied = true
				// Restart iteration since map was mutated
				break
			}
		}
		if !applied {
			break
		}
	}
}

// updateHeadsLocked updates the HEADS set when a message is applied.
//
// HEADS semantics: a message is a HEAD if no other currently-applied message
// lists it as a dependency. When env is applied:
//   - Remove all of env's deps from HEADS (they now have a child: env)
//   - Add env to HEADS (it has no children yet)
//
// Must be called with gl.mu held.
func (gl *GossipLog) updateHeadsLocked(env NetworkEnvelope) {
	// Remove parent messages from HEADS (they now have a child)
	for _, depID := range env.PrevMsgIDs {
		if depID != "" {
			delete(gl.heads, depID)
		}
	}
	// This message is now a HEAD
	gl.heads[env.MsgID] = true
}

// Heads returns a snapshot of the current HEAD message IDs.
// These are the most recent causally-applied messages with no known children.
func (gl *GossipLog) Heads() []string {
	gl.mu.RLock()
	defer gl.mu.RUnlock()

	heads := make([]string, 0, len(gl.heads))
	for h := range gl.heads {
		heads = append(heads, h)
	}
	return heads
}

// LogSize returns the number of applied messages in the log.
func (gl *GossipLog) LogSize() int {
	gl.mu.RLock()
	defer gl.mu.RUnlock()
	return len(gl.log)
}

// PendingSize returns the number of messages waiting for their dependencies.
func (gl *GossipLog) PendingSize() int {
	gl.mu.RLock()
	defer gl.mu.RUnlock()
	return len(gl.pending)
}
