const int PIN_CLOCK = 13;

const int PIN_LIGHTS_DATA_SHIFT = 12;
const int PIN_LIGHTS_DATA_LATCH = 11;
const int PIN_LIGHTS_DATA_OUT = 10;

const int PIN_PX_CROSSING = 9;

const int PIN_LED_DATA_SHIFT = 8;
const int PIN_LED_DATA_LATCH = 7;
const int PIN_LED_DATA_OUT = 6;

const int PIN_SWITCHES_DATA_SHIFT = 5;
const int PIN_SWITCHES_DATA_LATCH = 4;
const int PIN_SWITCHES_DATA_IN = 3;

const int CLOCK_CYCLE = 1000;
const int CLOCK_DUTY_HIGH = 500;

const int STATE_NS_GO = 1;
const int STATE_EW_GO = 2;
const int STATE_PX_GO = 3;
const int STATE_TRANSITION = 4;

int ns_duration = 3,
    ew_duration = 3,
    px_duration = 3;

int ns_countdown = ns_duration,
    ew_countdown = ew_duration,
    px_countdown = px_duration;

bool px_crossing = false,
     px_crossing_next = false;

int cycle_start = 0,
    cycle_state = HIGH;

int state, last_state, next_state;

void setup() {
    Serial.begin(19200);
    pinMode(PIN_LIGHTS_DATA_SHIFT, OUTPUT);
    pinMode(PIN_LIGHTS_DATA_OUT, OUTPUT);
    pinMode(PIN_LIGHTS_DATA_LATCH, OUTPUT);

    pinMode(PIN_LED_DATA_SHIFT, OUTPUT);
    pinMode(PIN_LED_DATA_OUT, OUTPUT);
    pinMode(PIN_LED_DATA_LATCH, OUTPUT);

    pinMode(PIN_SWITCHES_DATA_IN, INPUT);
    pinMode(PIN_SWITCHES_DATA_LATCH, OUTPUT);
    pinMode(PIN_SWITCHES_DATA_SHIFT, OUTPUT);

    pinMode(PIN_CLOCK, OUTPUT);
    pinMode(PIN_PX_CROSSING, INPUT);

    ns_duration = 3;
    ew_duration = 3;
    px_duration = 3;

    ns_countdown = ns_duration;
    ew_countdown = 0;
    px_countdown = 0;

    px_crossing = false;
    px_crossing_next = false;

    cycle_start = 0;
    cycle_state = HIGH;

    state = STATE_NS_GO;
    next_state = STATE_EW_GO;
    last_state = STATE_EW_GO;

    digitalWrite(PIN_SWITCHES_DATA_LATCH, LOW);
}

void loop() {
    int now = millis();
    bool rising_edge = false;
    
    if (now - cycle_start > CLOCK_CYCLE) {
        cycle_state = HIGH;
        cycle_start = now;
        rising_edge = true;
    } else if (cycle_state == HIGH && now - cycle_start > CLOCK_DUTY_HIGH) {
        cycle_state = LOW;
    }
    digitalWrite(PIN_CLOCK, cycle_state);

    
    if (rising_edge) {
        update_durations();
        update_leds();
        if (!px_crossing && digitalRead(PIN_PX_CROSSING)) {
            Serial.print("PX Crossing!\n");
            px_crossing = true;
        }
        Serial.print("PX: ");
        Serial.print(px_crossing ? "1" : "0");
        Serial.print(" State: ");
        Serial.print(state, DEC);

        byte light_state = 0;
        // Initially set the reds to HIGH
        bitWrite(light_state, 2, HIGH);
        bitWrite(light_state, 5, HIGH);
        if (state == STATE_NS_GO) {
            bitWrite(light_state, 0, HIGH);
            bitWrite(light_state, 2, LOW);
            
            Serial.print(" Countdown: ");
            Serial.print(ns_countdown, DEC);
            ns_countdown--;
            
            if (ns_countdown == 0) {
                state = STATE_TRANSITION;
                next_state = STATE_EW_GO;
                last_state = STATE_NS_GO;
                if (px_crossing) {
                    px_crossing_next = true;
                }
                Serial.print(" PX next?: ");
                Serial.print(px_crossing_next ? "y" : "n");
            }
        } else if (state == STATE_EW_GO) {
            bitWrite(light_state, 3, HIGH);
            bitWrite(light_state, 5, LOW);
            Serial.print(" Countdown: ");
            Serial.print(ew_countdown, DEC);
            ew_countdown--;
            if (ew_countdown == 0) {
                state = STATE_TRANSITION;
                next_state = STATE_NS_GO;
                last_state = STATE_EW_GO;
                
                if (px_crossing) {
                    px_crossing_next = true;
                }
                Serial.print(" PX next?: ");
                Serial.print(px_crossing_next ? "y" : "n");
            }
        } else if (state == STATE_PX_GO) {
            px_countdown--;
            Serial.print(" Countdown: ");
            Serial.print(ew_countdown, DEC);
            if (px_countdown == 0) {
                state = STATE_TRANSITION;
                last_state = STATE_PX_GO;
            }
        } else if (state == STATE_TRANSITION) {
            Serial.print(" PX next?: ");
            Serial.print(px_crossing_next ? "y" : "n");
            if (last_state == STATE_NS_GO) {
                bitWrite(light_state, 1, HIGH);
                bitWrite(light_state, 2, LOW);
            } else if (last_state == STATE_EW_GO) {
                bitWrite(light_state, 4, HIGH);
                bitWrite(light_state, 5, LOW);
            }

            if (px_crossing_next) {
                px_crossing = false;
                px_crossing_next = false;
                px_countdown = px_duration;
                state = STATE_PX_GO;
            } else {
                if (next_state == STATE_NS_GO) {
                    ns_countdown = ns_duration;
                    bitWrite(light_state, 1, HIGH);
                } else if (next_state == STATE_EW_GO) {
                    ew_countdown = ew_duration;
                    bitWrite(light_state, 4, HIGH);
                }
                state = next_state;
            }
        }
        digitalWrite(PIN_LIGHTS_DATA_LATCH, LOW);
        shiftOut(PIN_LIGHTS_DATA_OUT, PIN_LIGHTS_DATA_SHIFT, MSBFIRST, light_state);
        digitalWrite(PIN_LIGHTS_DATA_LATCH, HIGH);
        Serial.print("\n");
        Serial.print(light_state, BIN);
        Serial.print("\n");
    }
}

void update_leds() {
    byte led = 0;
    led = px_countdown << 4;
    led |= px_duration;

    digitalWrite(PIN_LED_DATA_LATCH, LOW);
    shiftOut(PIN_LED_DATA_OUT, PIN_LED_DATA_SHIFT, MSBFIRST, led);
    Serial.print("LEDs: ");
    Serial.println(led, BIN);
    
    led = ew_duration << 4;
    led |= ns_duration;

    shiftOut(PIN_LED_DATA_OUT, PIN_LED_DATA_SHIFT, MSBFIRST, led);
    digitalWrite(PIN_LED_DATA_LATCH, HIGH);
}

void update_durations() {
    digitalWrite(PIN_SWITCHES_DATA_LATCH, HIGH);
    // Account for propagation delay
    delayMicroseconds(20);
    digitalWrite(PIN_SWITCHES_DATA_LATCH, LOW);

    byte switches = myShiftIn(
        PIN_SWITCHES_DATA_IN,
        PIN_SWITCHES_DATA_SHIFT
    );
    
    if (switches & 1) {
        ns_duration++;

        if (ns_duration >= 10) {
            ns_duration = 1;
        }
    }
    
    if (switches & 2) {
        ns_duration--;
        if (ns_duration <= 0) {
            ns_duration = 9;
        }
    }

    if (switches & 4) {
        ew_duration++;
        if (ew_duration >= 10) {
            ew_duration = 1;
        }
    }

    if (switches & 8) {
        ew_duration--;
        if (ew_duration <= 0) {
            ew_duration = 9;
        }
    }

    if (switches & 16) {
        px_duration++;
        if (px_duration >= 10) {
            px_duration = 1;
        }
    }

    if (switches & 32) {
        px_duration--;
        if (px_duration <= 0) {
            px_duration = 9;
        }
    }

    Serial.print("\n");
}

byte myShiftIn(int data_pin, int clock_pin) {
    Serial.print("Switches: ");

    int i;
    int temp = 0;
    int pinState;
    byte data_in = 0;

    for (i = 7; i >= 0; i--) {
        digitalWrite(clock_pin, 0);
        delayMicroseconds(0.2);
        temp = digitalRead(data_pin);
        if (temp) {
            Serial.print("1");
            data_in = data_in | (1 << i);
        } else {
            Serial.print("0");
            pinState = 0;
        }
        digitalWrite(clock_pin, 1);
    }
    Serial.print("\n");
    return data_in;
}
