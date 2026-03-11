# 🏠 FPGA Smart Home & Environment Monitoring System

> **Verilog HDL** 기반의 실시간 환경 감시 및 스마트 홈 제어 시스템입니다. 
> FPGA(Basys3)를 중앙 제어 장치로 활용하여 시간, 온도, 습도를 정밀하게 측정하고, 분석된 데이터를 바탕으로 모터와 부저 등 하드웨어를 능동적으로 제어합니다.

---

## 🚀 주요 기능 (Key Features)

- **실시간 시계 (RTC) 제어:** DS1302 칩을 FSM 기반 3-Wire 통신으로 제어하여 현재 시각을 1ms 주기로 모니터링 및 UART를 통한 시간 설정 지원.
- **정밀 환경 감지:** DHT11 센서의 펄스 길이를 마이크로초(µs) 단위로 판독하여 온도와 습도 데이터 수집.
- **지능형 자동 제어:**
  - **온도 관리:** 28°C 이상 시 DC 모터 자동 가동 (Cooling Fan).
  - **습도 관리:** 70% 이상 시 서보 모터 구동 (Auto Window).
- **사용자 인터페이스 (UI/UX):**
  - **4-Digit FND:** 시간 및 온습도 데이터를 선택적으로 출력하며, 설정 모드 시 디지트 블링킹 기능 제공.
  - **UART Bridge:** PC 터미널과 115200bps 속도로 통신하여 실시간 상태 로그 전송 및 사용자 명령 수신.
- **시스템 알림:** 정각 알림 및 주요 이벤트 발생 시 부저(Buzzer) 피드백 제공.

---

## 🛠 시스템 아키텍처 (System Architecture)

효율적인 설계와 유지보수를 위해 **3-Layer 계층형 구조**로 설계되었습니다.

### 1. Peripheral I/O Cluster (Sense & Act)
하드웨어와 직접 통신하는 하위 드라이버 계층입니다.
- `ds1302_controller`: FSM 기반 RTC 통신 전담 드라이버.
- `dht11_controller`: 타이밍 기반 온습도 판독 및 Checksum 검증.
- `motor_controller`: PWM 신호를 통한 액추에이터 제어.

### 2. Communication Bridge (Protocol Gateway)
중앙 본부와 말단 장치 사이의 데이터 중계 및 외부 통신 전담 계층입니다.
- UART 송수신 데이터 관리.
- PC 명령어를 시스템 제어 신호(`load_en`)로 변환 및 데이터 파싱.

### 3. Central Control Hub (Logic Center)
시스템의 전체 흐름과 제어 정책을 결정하는 최상위 계층입니다.
- **Threshold Logic:** 온도(28°C), 습도(70%) 임계치 비교 및 제어 신호 생성.
- **Tick Generation:** 시스템 표준 박자(1Hz, 1kHz, 1MHz) 생성 및 배포.

---

## 📡 FSM 설계: DS1302 Controller

안정적인 데이터 정합성을 위해 10가지 상태를 가진 **Finite State Machine**을 설계하였습니다.



1. **S_IDLE:** 시간 설정 요청(`load_req`) 확인 후 Read/Write 경로 결정.
2. **Command Phase:** 명령어(`0xBE`, `0xBF`)를 비트 단위로 전송하여 칩의 모드 설정.
3. **Data Phase:** 64비트(8바이트) Burst 데이터를 연속 교환하여 시간 오차 최소화.
4. **S_FINISH:** CE 신호 해제 및 통신 세션 종료 후 안정화.

---

## 🔌 하드웨어 구성 (Hardware Configuration)

| Component | Pin Type | Description |
| :--- | :--- | :--- |
| **FPGA Board** | Basys3 | Artix-7 XC7A35T |
| **DS1302** | 3-Wire (CE, SCLK, IO) | Real-time Clock Interface |
| **DHT11** | Single-bus (Inout) | Temp/Humi Sensor Data Line |
| **DC Motor** | PWM | Automatic Cooling Fan |
| **UART (USB)** | RX, TX | PC Serial Link (115200 bps) |

---

## 📖 실행 방법 (How to Run)

1. **환경 구축:** Vivado ML Edition (2020.1 이상 권장).
2. **보드 연결:** Digilent Basys3 보드를 PC에 연결.
3. **컴파일 및 업로드:** `Basys3_Master.xdc` 파일을 통해 핀 매핑을 확인하고 비트스트림 생성 후 FPGA에 업로드.
4. **모니터링:** - FND에 실시간 시계가 표시되는지 확인.
   - PC에서 터미널 프로그램(Tera Term, PuTTY 등)을 열고 115200 Baud rate로 접속하여 데이터 로그 확인.

---
application/miri-canvas-node

