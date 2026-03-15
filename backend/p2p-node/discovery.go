package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/p2p/discovery/mdns"
)

const discoveryServiceTag = "openrescue.p2p"

// discoveryNotifee gets notified when we find a new peer via mDNS discovery
type discoveryNotifee struct {
	h host.Host
}

// HandlePeerFound connects to peers discovered via mDNS
func (n *discoveryNotifee) HandlePeerFound(pi peer.AddrInfo) {
	fmt.Printf("mDNS Discovery: Found peer %s\n", pi.ID)
	// Don't try to connect to ourselves
	if pi.ID == n.h.ID() {
		return
	}

	// Connect to the peer
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()
	
	err := n.h.Connect(ctx, pi)
	if err != nil {
		fmt.Printf("mDNS Discovery: Failed connecting to peer %s: %s\n", pi.ID.String(), err)
	} else {
		fmt.Printf("mDNS Discovery: Automatically connected to peer %s\n", pi.ID.String())
	}
}

// setupDiscovery creates an mDNS discovery service
func setupDiscovery(h host.Host) error {
	s := mdns.NewMdnsService(h, discoveryServiceTag, &discoveryNotifee{h: h})
	if s == nil {
		return fmt.Errorf("failed creating mDNS service")
	}
	
	if err := s.Start(); err != nil {
		return fmt.Errorf("failed starting mDNS service: %v", err)
	}
	
	log.Printf("mDNS Peer Discovery started (service tag: %s)\n", discoveryServiceTag)
	return nil
}
