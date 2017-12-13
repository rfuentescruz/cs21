const int PIN_INT = 2;
const int PINOUT_A0 = 3;
const int PINOUT_A1 = 4;
const int PINOUT_A2 = 5;
const int PINOUT_A3 = 6;
const int PIN_SELECTOR = 7;
const int PIN_WRITE = 8;
const int PIN_MODE = 9;

const int PIN_CLOCK = 13;
const int ANALOG_PIN0 = A0;

const int MODE_COUNTDOWN = 0;
const int MODE_DISTANCE = 1;

const int V_MIN = 400;  // Analog reading when object is far from the sensor
const int V_MAX = 1000; // Analog reading when object is closest to the sensor
const int V_RANGE = V_MAX - V_MIN;

int mode = MODE_COUNTDOWN;
int count = 9;
int cycle_start = 0, cycle_state = HIGH, cycle_reset = 1;

unsigned long last_interrupt = millis();

void reset() {
    mode = MODE_COUNTDOWN;
    count = 9;
    cycle_reset = 1;
    cycle_state = HIGH;
}

void setup() {
    pinMode(PINOUT_A0, OUTPUT);
    pinMode(PINOUT_A1, OUTPUT);
    pinMode(PINOUT_A2, OUTPUT);
    pinMode(PINOUT_A3, OUTPUT);
    pinMode(PIN_SELECTOR, OUTPUT);
    pinMode(PIN_WRITE, OUTPUT);
    pinMode(PIN_CLOCK, OUTPUT);
    analogReference(INTERNAL);
    pinMode(PIN_INT, INPUT_PULLUP);
    attachInterrupt(0, switch_mode, FALLING);

    Serial.begin(9600);
    reset();
}

void loop() {
    int now = millis();
    bool rising_edge = false;
    int reading = analogRead(A0);

    if (cycle_reset || now - cycle_start > 1000) {
        cycle_reset = 0;
        cycle_state = HIGH;
        cycle_start = now;
        rising_edge = true;
    } else if (cycle_state == HIGH && now - cycle_start > 500) {
        cycle_state = LOW;
    }
    digitalWrite(PIN_CLOCK, cycle_state);

    if (mode == MODE_COUNTDOWN) {
        digitalWrite(PIN_MODE, LOW);
        if (rising_edge) {
            output_digit(count, 1);
            output_digit(0, 0);

            if (count <= 0) {
                mode = MODE_DISTANCE;
                count = 9;
            } else {
                count--;
            }
        }
    }
    
    if (mode == MODE_DISTANCE) {
        digitalWrite(PIN_MODE, HIGH);
        int reading = 1023 - analogRead(ANALOG_PIN0);
        reading = min(V_RANGE - 6, 1023 - reading);
        int pct = (int) ((double) reading / V_RANGE * 100);

        output_digit(pct / 10, 1);
        output_digit(pct % 10, 0);
    }
}

void switch_mode() {
    int now = millis();
    // Poor man's debounce
    if (now - last_interrupt < 50) {
        return;
    }
    last_interrupt = now;

    if (mode == MODE_DISTANCE) {
        reset();
    } else {
        mode = MODE_DISTANCE;
    }
}

void output_digit(int digit, int selector) {
    digitalWrite(PIN_WRITE, LOW);
    digitalWrite(PINOUT_A0, digit & 1);
    digitalWrite(PINOUT_A1, digit & 2);
    digitalWrite(PINOUT_A2, digit & 4);
    digitalWrite(PINOUT_A3, digit & 8);

    digitalWrite(PIN_SELECTOR, selector);
    digitalWrite(PIN_WRITE, HIGH);
    digitalWrite(PIN_WRITE, LOW);
}
