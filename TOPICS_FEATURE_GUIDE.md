# Topics Feature Guide

## Overview
The Topics feature provides a organized view of all MQTT topics with their messages, allowing users to browse topic-specific conversations in dedicated rooms.

## Features

### Topics Page
- **Topic List**: Shows all discovered MQTT topics in a clean card layout
- **Message Count**: Displays number of messages for each topic
- **Subscription Status**: Visual indicator showing which topics you're subscribed to
- **Last Message Preview**: Shows a preview of the most recent message in each topic
- **Real-time Updates**: Topics and message counts update automatically as new messages arrive

### Topic Room Page
- **Topic-specific Chat**: View all messages published to a specific topic in a chat-like interface
- **Message History**: See chronological order of all messages for that topic
- **Send Messages**: Publish new messages directly to the topic
- **Subscribe Toggle**: Subscribe/unsubscribe to the topic for real-time updates
- **Message Timestamps**: Clear timestamps showing when messages were sent

## How to Access

### Navigation
1. **Host Mode**: After starting a broker session, tap the "Topics" tab at the bottom
2. **Client Mode**: After connecting to a broker, tap the "Topics" tab at the bottom

### Using Topics
1. **Browse Topics**: See all available topics on the Topics page
2. **Enter Topic Room**: Tap any topic card to enter that topic's dedicated room
3. **Send Messages**: Use the message input at the bottom to publish to the topic
4. **Subscribe**: Tap the "Subscribe" button to receive real-time updates for that topic

## Topic Discovery
- **Automatic Detection**: Topics are automatically discovered from MQTT message logs
- **Default Topics**: Always includes the default topic (`test/topic`) and share topic (`share/topic`)
- **Dynamic Updates**: New topics appear automatically when messages are published to them

## Visual Indicators
- **Green Border**: Subscribed topics have a green border and "SUBSCRIBED" badge
- **Message Count**: Shows total number of messages for each topic
- **Last Activity**: Timestamp showing when the last message was received
- **Connection Status**: Warning banner when not connected to MQTT broker

## Benefits
- **Organized Communication**: Keep track of different conversation topics separately
- **Message History**: Easy access to past messages for each topic
- **Selective Subscription**: Choose which topics to monitor actively
- **Real-time Updates**: See new messages as they arrive in topic-specific rooms

## Technical Details
- **Message Parsing**: Extracts topic information from MQTT service logs
- **Real-time Updates**: Listens to MQTT service changes for automatic updates
- **Navigation**: Seamless navigation between topics list and individual topic rooms
- **Subscription Management**: Direct integration with MQTT service subscription system
