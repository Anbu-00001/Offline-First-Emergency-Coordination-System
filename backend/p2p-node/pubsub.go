package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	pubsub "github.com/libp2p/go-libp2p-pubsub"
	"github.com/libp2p/go-libp2p/core/host"
)

const IncidentTopic = "openrescue.incident"

// IncidentMessage defines the schema for our P2P broadcasts
type IncidentMessage struct {
	Type        string  `json:"type"`
	IncidentID  string  `json:"incident_id"`
	Lat         float64 `json:"lat"`
	Lon         float64 `json:"lon"`
	Priority    string  `json:"priority"`
	Timestamp   int64   `json:"timestamp"`
	DeviceID    string  `json:"device_id"`
}

type PubSubManager struct {
	ctx      context.Context
	ps       *pubsub.PubSub
	topic    *pubsub.Topic
	sub      *pubsub.Subscription
	host     host.Host
	msgChan  chan IncidentMessage
}

// setupPubSub initializes GossipSub and subscribes to the incident topic
func setupPubSub(ctx context.Context, h host.Host, msgChan chan IncidentMessage) (*PubSubManager, error) {
	// Create a new GossipSub routing instance
	ps, err := pubsub.NewGossipSub(ctx, h)
	if err != nil {
		return nil, fmt.Errorf("failed to create GossipSub: %w", err)
	}

	// Join the topic
	topic, err := ps.Join(IncidentTopic)
	if err != nil {
		return nil, fmt.Errorf("failed to join topic: %w", err)
	}

	// Subscribe to the topic
	sub, err := topic.Subscribe()
	if err != nil {
		return nil, fmt.Errorf("failed to subscribe to topic: %w", err)
	}

	manager := &PubSubManager{
		ctx:     ctx,
		ps:      ps,
		topic:   topic,
		sub:     sub,
		host:    h,
		msgChan: msgChan,
	}

	// Start listening for messages in the background
	go manager.listenLoop()

	log.Printf("Joined GossipSub topic: %s", IncidentTopic)
	return manager, nil
}

// listenLoop continuously reads from the subscription
func (m *PubSubManager) listenLoop() {
	for {
		msg, err := m.sub.Next(m.ctx)
		if err != nil {
			log.Printf("Error reading from GossipSub: %s\n", err)
			return
		}

		// Don't process our own messages internally
		if msg.ReceivedFrom == m.host.ID() {
			continue
		}

		// Parse the JSON message
		var incMsg IncidentMessage
		if err := json.Unmarshal(msg.Data, &incMsg); err != nil {
			log.Printf("Failed to unmarshal GossipSub message: %s\n", err)
			continue
		}

		log.Printf("Received incident broadcast from peer %s: %s\n", msg.ReceivedFrom, incMsg.IncidentID)

		// Forward to the channel for the WebSocket API to pick up
		select {
		case m.msgChan <- incMsg:
		default:
			log.Println("Message channel full or blocking, dropping message")
		}
	}
}

// Broadcast serializes and publishes an incident message
func (m *PubSubManager) Broadcast(msg IncidentMessage) error {
	// Ensure the DeviceID is set to our peer ID
	msg.DeviceID = m.host.ID().String()

	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	return m.topic.Publish(m.ctx, data)
}
