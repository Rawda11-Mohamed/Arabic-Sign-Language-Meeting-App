# Arabic Sign Language Recognition for Online Meetings (Ishara)

## Overview

Ishara is an AI-powered platform designed to improve communication between Deaf and Hard-of-Hearing (DHH) individuals and hearing participants during online meetings.

The system recognizes Arabic Sign Language (ArSL) gestures in real time and translates them into Arabic text while also providing Speech-to-Text functionality for two-way communication. It combines Computer Vision, Deep Learning, and WebRTC technologies to create an accessible and inclusive meeting experience.

---

## Features

* Real-time Arabic Sign Language recognition
* Hand detection and tracking using MediaPipe
* AI-powered gesture recognition
* Sign-to-Text translation
* Speech-to-Text transcription
* Cross-platform Flutter mobile application
* Online meeting support using WebRTC
* User authentication and meeting management
* Low-latency real-time inference

---

## System Architecture

The project consists of four main components:

```text
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

* Python
* TensorFlow / Keras
* OpenCV
* MediaPipe
* YOLO
* LSTM
* Computer Vision

### Mobile Development

* Flutter
* Dart

### Backend

* Flask / FastAPI
* Node.js
* WebSocket

### Communication

* WebRTC

---

## Project Structure

```text
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

* User Registration & Login
* Join/Create Online Meetings
* Schedule Meetings
* Real-Time Sign Recognition
* Speech-to-Text
* User Profile Management
* Meeting History
* Fast Communication Phrases

---

## Screenshots



<p align="center">
  <img src="https://github.com/user-attachments/assets/ab48eecb-71ab-44ab-9510-4f520770aea1" width="200"/>
  <img src="https://github.com/user-attachments/assets/69685cc7-7d44-4dd4-884a-b5d129557770" width="200"/>
  <img src="https://github.com/user-attachments/assets/385a0d12-3ec3-4499-a1c0-1d53ad171341" width="200"/>
  <img src="https://github.com/user-attachments/assets/f77b39af-85f2-4271-8ad0-036c97ba9f97" width="200"/>
</p>



<p align="center">
  <img src="https://github.com/user-attachments/assets/6aed06d1-e4ea-4d47-a726-543a69776d0a" width="200"/>
  <img src="https://github.com/user-attachments/assets/82c059ba-7073-4dac-aa4f-09bc84eab5e9" width="200"/>
  <img src="https://github.com/user-attachments/assets/fede6cc0-b1e0-4ae5-b85c-a3a61f45a739" width="200"/>
  <img src="https://github.com/user-attachments/assets/07091a3e-8906-48cd-b35e-df51a3ce1d6a" width="200"/>
</p>



<p align="center">
  <img src="https://github.com/user-attachments/assets/51e0b223-09a2-4e36-95f2-15f7785276cd" width="200"/>
  <img src="https://github.com/user-attachments/assets/1cd70387-ad3c-4d00-88c9-7139d4f5fff3" width="200"/>
  <img src="https://github.com/user-attachments/assets/f7f52d36-11b3-4f80-8fb8-6ea0d6e24d42" width="200"/>
  <img src="https://github.com/user-attachments/assets/9a7d4adf-614b-471a-8767-9dbb42d2e786" width="200"/>
</p>



<p align="center">
  <img src="https://github.com/user-attachments/assets/18ed7459-5d73-4e33-827a-f139cee04ba5" width="200"/>
</p>

---

## Future Improvements

* Sentence-level Arabic Sign Language recognition
* Larger Arabic Sign Language datasets
* Multi-hand gesture recognition
* Arabic Text-to-Speech
* Cloud deployment
* Web application support
* Higher recognition accuracy
* Additional Arabic dialect support

---

## Installation

### Clone the Repository

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

### Run the Flutter Application

```bash
flutter pub get
flutter run
```

---

## Results

The project successfully demonstrates:

* Real-time Arabic Sign Language recognition
* Low-latency communication during online meetings
* AI-powered gesture classification
* Integration of Sign-to-Text and Speech-to-Text into a unified communication platform

---

## License

This project was developed as a Graduation Project for the Bachelor's Degree in Computer Science (2025–2026). It is intended for educational and research purposes.
