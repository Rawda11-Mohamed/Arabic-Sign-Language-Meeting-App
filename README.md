# Arabic Sign Language Recognition for Online Meetings (Ishara)

## Overview

Ishara is an AI-powered platform designed to improve communication between Deaf and Hard-of-Hearing (DHH) individuals and hearing participants during online meetings.

The system recognizes Arabic Sign Language (ArSL) gestures in real time and translates them into Arabic text while also providing Speech-to-Text functionality for two-way communication. It combines Computer Vision, Deep Learning, and WebRTC technologies to create an accessible and inclusive meeting experience. 

---

## Features

-  Real-time Arabic Sign Language recognition
-  Hand detection and tracking using MediaPipe
-  AI-powered gesture recognition
-  Sign-to-Text translation
-  Speech-to-Text transcription
-  Cross-platform Flutter mobile application
-  Online meeting support using WebRTC
-  User authentication and meeting management
-  Low-latency real-time inference

---

## System Architecture

The project consists of four main components:

```
Flutter Mobile App
        │
        ▼
WebRTC Video Streaming
        │
        ▼
Flask/FastAPI Backend
        │
        ▼
AI Recognition Models
        │
        ▼
Arabic Text Output
```

---

## Technologies Used

### Artificial Intelligence

- Python
- TensorFlow / Keras
- OpenCV
- MediaPipe
- YOLO
- LSTM
- Computer Vision

### Mobile Development

- Flutter
- Dart

### Backend

- Flask / FastAPI
- Node.js
- WebSocket

### Communication

- WebRTC

---

## Project Structure

```
├── AI_Model/
│   ├── Dataset
│   ├── Training
│   ├── Models
│   └── Prediction
│
├── Backend/
│   ├── API
│   ├── Authentication
│   └── WebSocket
│
├── Flutter_App/
│   ├── Screens
│   ├── Services
│   ├── Widgets
│   └── Models
│
├── Signaling_Server/
│
├── Documentation/
│
└── README.md
```

---

## Machine Learning Pipeline

1. Capture live camera frames
2. Detect hands using MediaPipe
3. Extract hand landmarks/features
4. Process features using Deep Learning models
5. Predict Arabic sign
6. Convert prediction into Arabic text
7. Display translated text in real time

---

## Main Functionalities

- User Registration & Login
- Join/Create Online Meetings
- Schedule Meetings
- Real-Time Sign Recognition
- Speech-to-Text
- User Profile Management
- Meeting History
- Fast Communication Phrases

---

## Future Improvements

- Sentence-level Arabic Sign Language recognition
- Larger Arabic Sign Language datasets
- Multi-hand gesture recognition
- Arabic Text-to-Speech
- Cloud deployment
- Web application support
- Higher recognition accuracy
- Additional Arabic dialect support

---

## Installation

### Clone the repository

```bash
git clone https://github.com/your-username/Arabic-Sign-Language-Recognition.git
```

### Install Backend Dependencies

```bash
pip install -r requirements.txt
```

### Run the Backend

```bash
python app.py
```

### Run Flutter Application

```bash
flutter pub get
flutter run
```

---

## Results

The project successfully demonstrates:

- Real-time Arabic Sign Language recognition
- Low-latency communication during online meetings
- AI-powered gesture classification
- Integration of Sign-to-Text and Speech-to-Text into a unified communication platform

---

## License

This project was developed as a Graduation Project for the Bachelor's Degree in Computer Science (2025–2026). It is intended for educational and research purposes. 

