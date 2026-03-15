package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/libp2p/go-libp2p"
)

func main() {
	// Setup context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 1. Initialize libp2p host
	// Using default multiaddresses (listen on all interfaces)
	host, err := libp2p.New(
		libp2p.ListenAddrStrings("/ip4/0.0.0.0/tcp/0"),
	)
	if err != nil {
		log.Fatalf("Failed to create libp2p host: %v", err)
	}
	defer host.Close()
	
	fmt.Printf("P2P Node started with ID: %s\n", host.ID().String())
	for _, addr := range host.Addrs() {
		fmt.Printf("Listening on: %s/p2p/%s\n", addr.String(), host.ID().String())
	}

	// 2. Setup mDNS discovery
	if err := setupDiscovery(host); err != nil {
		log.Fatalf("Failed to setup mDNS discovery: %v", err)
	}

	// Channel for messages received from GossipSub to be sent to WebSocket clients
	msgChan := make(chan IncidentMessage, 100)

	// 3. Setup PubSub (GossipSub)
	pubSubManager, err := setupPubSub(ctx, host, msgChan)
	if err != nil {
		log.Fatalf("Failed to setup PubSub: %v", err)
	}

	// 4. Start HTTP/WS API server on port 7000
	apiServer := NewAPIServer(7000, pubSubManager, msgChan)
	if err := apiServer.Start(); err != nil {
		log.Fatalf("Failed to start API server: %v", err)
	}

	fmt.Println("P2P Daemon is running. Press CTRL+C to stop.")

	// Wait for interrupt signal
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGTERM)
	<-ch
	
	fmt.Println("Shutting down P2P Daemon...")
}
