# Stride Probe

> *The first step to a stress-free you.*

**Stride Probe** is a Flutter-based mobile application that performs **multi-modal stress assessment** by combining photoplethysmography (PPG), cognitive testing, behavioral analysis, and clinically validated questionnaires into a single composite stress score.

<p align="center">
  <img src="assets/images/logo.png" alt="Stride Probe Logo" width="120"/>
</p>

---

## Overview

Stride Probe measures stress through four complementary modalities:

| Modality | Method | What It Measures |
|----------|--------|-----------------|
| **Physiological** | Camera-based PPG | Heart rate (BPM), Heart Rate Variability (HRV), signal quality |
| **Cognitive** | Interactive tests | Stroop interference, speeded reasoning, pattern memory recall |
| **Behavioral** | Accelerometer + Gyroscope | Restlessness, movement intensity, hesitation patterns |
| **Self-Reported** | WHO-5 Well-Being Index | Subjective well-being and perceived stress |

These are fused into a **7-component proprietary stress algorithm** (0–100 scale) with a binary stressed/not-stressed label and confidence score.

---

## Features

### Contactless Heart Rate & HRV
- Real-time PPG measurement using the **phone's camera and flash** — no external hardware required
- On-device **4th-order Butterworth IIR bandpass filter** (0.5–3.5 Hz) implemented as Direct-Form II Transposed biquad cascades
- **Linear detrending** via least-squares regression for motion artifact removal
- **Adaptive peak detection** with physiological refractory period (0.3s refractory, 200 BPM max)
- **IBI-based BPM** with median filtering, outlier rejection (>20% from median), and weighted moving average smoothing
- **HRV metrics**: RMSSD, SDNN, mean IBI, coefficient of variation — with qualitative interpretation
- **3-component confidence scoring**: SNR (40%), IBI regularity via CoV (45%), peak count sufficiency (15%)

### Cognitive Stress Tests
| Test | Description | Format |
|------|-------------|--------|
| **Stroop Test** | Classic color-word interference with 4 subtypes (classic, reverse color patch, spatial arrow direction, auditory word position) | 10 questions, 3s timer, streak bonuses |
| **Speed Answer Test** | Rapid math, logic, and pattern-recognition problems | 10 questions, 3s timer, speed bonus (<2s), streak bonuses |
| **Pattern Memory Test** | Visual-spatial recall on 3×3 / 4×4 grids with shapes (circle, triangle, diamond, star, hexagon, square) and colors | 10 levels, 3s memorize / 5s recall |

### Behavioral Analysis
- **Accelerometer + gyroscope** capture via `sensors_plus` at ~10 Hz
- Real-time feature extraction: movement intensity, variance, peak count, zero-crossing rate, activity level classification
- **Restlessness score**: weighted combination of accelerometer and gyroscope variance
- **Hesitation detection** (>3s pause) and **rapid guess detection** (<0.5s)
- **Personal baseline week**: first 5 sessions establish individualized movement and physiological baselines

### WHO-5 Well-Being Index
- Clinically validated 5-question mental well-being screening tool
- Administered pre-test (baseline) and post-test (stress response)
- Normalized score inverted and used as a 30% weighted component

### Composite Stress Score
The proprietary algorithm weights 7 normalized components:

| Component | Weight | Source |
|-----------|--------|--------|
| WHO-5 Stress | 30% | Inverted WHO-5 normalized score |
| HRV Stress | 20% | Inverse of normalized RMSSD |
| Cognitive Stress | 15% | Stroop interference, response time, accuracy, errors |
| HR Stress | 10% | Normalized heart rate (60–100 BPM → 0–1) |
| Behavior Stress | 10% | Restlessness + baseline deviation |
| Self-Report Stress | 10% | Normalized self-reported stress |
| Baseline Stress | 5% | Deviation from personal baseline HR & HRV |

### User Dashboard
- **Weekly bar chart** with real-time Supabase subscriptions — updates live when a new score is computed
- **Personalized recommendations** adapting to stress level (breathing exercises, walks, mindfulness)
- **Mood tracking**: sleep, mood, daily step count (via `pedometer` package)
- **Profile page** with test history, cognitive accuracy bars, heart rate / HRV summary

---

## Architecture

```
lib/
├── config/              # Supabase configuration
│   └── supabase_config.dart
├── core/
│   └── theme/           # AppColors (centralized palette)
├── models/              # Data classes & enums
│   ├── ppg_data.dart
│   ├── sensor_data.dart
│   ├── sensor_reading_result.dart
│   ├── test_stage.dart
│   ├── question_model.dart
│   ├── questions.dart
│   ├── stroop_test_model.dart
│   ├── pattern_memory_model.dart
│   └── speed_answer_model.dart
├── screens/             # UI screens
│   ├── splash.dart
│   ├── onboarding.dart
│   ├── Login.dart
│   ├── Register.dart
│   ├── Home.dart
│   ├── test_screen.dart
│   ├── test_map_screen.dart       # Test flow orchestrator
│   ├── ppg_instruction_screen.dart
│   ├── ppg_test_screen.dart
│   ├── questionnaire_test_screen.dart
│   ├── stroop_test_screen.dart
│   ├── speed_answer_test_screen.dart
│   ├── pattern_memory_test_screen.dart
│   ├── profile_screen.dart
│   ├── terms_conditions_screen.dart
│   └── privacy_policy_screen.dart
├── services/            # Business logic & data processing
│   ├── auth_service.dart
│   ├── camera_service.dart
│   ├── ppg_service.dart           # DSP pipeline (528 lines)
│   ├── sensor_capture_service.dart
│   ├── sensor_service.dart
│   ├── database_service.dart
│   ├── session_manager.dart
│   ├── step_service.dart
│   └── stress_score_service.dart  # Scoring engine (388 lines)
├── utils/
│   └── ppg_test_helper.dart
├── widget/              # Reusable UI components
│   ├── bottom_nav_bar.dart
│   ├── custom_button.dart
│   ├── wave_clipper.dart
│   ├── home/greeting_header.dart
│   ├── home/mood_section.dart
│   ├── home/recommendation_card.dart
│   ├── home/stress_score_card.dart
│   └── home/weekly_insights_card.dart
└── main.dart
```

### Test Flow

The app guides users through a **7-stage sequential assessment**:

```
PPG Pre (30s) → Questionnaire Pre → Stroop Test → Speed Answer Test
→ Pattern Memory Test → Questionnaire Post → PPG Post (30s)
```

A 30-second accelerometer/gyroscope baseline is captured before the test begins. On completion, the stress score is computed and saved to Supabase in real time.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter / Dart |
| **Auth & Database** | Supabase (PostgreSQL, RLS, realtime subscriptions) |
| **Camera** | `camera` — YUV420 image stream for PPG |
| **Sensors** | `sensors_plus` — accelerometer & gyroscope |
| **Pedometer** | `pedometer` — daily step tracking |
| **Animations** | `lottie` — splash & onboarding |
| **State Management** | setState + Stream-based (PPG), ValueNotifier (steps) |
| **Local Storage** | `shared_preferences` |
| **Permissions** | `permission_handler` |
| **Signal Processing** | Custom 4th-order IIR Butterworth filter (Direct-Form II Transposed), linear detrending, adaptive peak detection |

---

## Getting Started

### Prerequisites
- Flutter SDK ^3.11.3
- A Supabase project with the required tables

### Setup

```bash
# Clone the repository
git clone https://github.com/your-org/stride_probe.git
cd stride_probe

# Install dependencies
flutter pub get

# Configure Supabase
# Edit lib/config/supabase_config.dart with your Supabase URL and anon key

# Run the app
flutter run
```

### Required Supabase Tables
- `test_sessions`
- `who5_responses`
- `cognitive_metrics`
- `physiological_metrics`
- `sensor_behavior_metrics`
- `stress_scores`
- `user_baselines`

---

## Signal Processing Pipeline

The PPG service (`lib/services/ppg_service.dart`) implements a complete on-device DSP pipeline:

1. **Signal Acquisition** — Samples center 20% of the Y (luminance) plane from YUV420 camera frames
2. **Linear Detrending** — Least-squares line-fit removal (superior to mean subtraction)
3. **Bandpass Filtering** — 4th-order Butterworth IIR (0.5–3.5 Hz), 2 cascaded biquad sections, pre-computed coefficients for 30 Hz sample rate
4. **Adaptive Peak Detection** — Adaptive threshold (mean + 0.5σ over 3s window) + 0.3s physiological refractory period
5. **IBI Calculation** — Inter-beat intervals → median IBI → BPM → weighted moving average (last 5 estimates)
6. **Outlier Rejection** — Removes IBIs deviating >20% from median
7. **Confidence Scoring** — 3-component: SNR (40%), IBI regularity via CoV (45%), peak count sufficiency (15%)

---

## License

This project is private and not licensed for public distribution.
