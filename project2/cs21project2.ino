const int PIN_CLOCK = 13;
const int PIN_DATA_OUT = 12;
const int PIN_DATA_WRITE = 11;
const int PIN_DATA_CLOCK = 10;
const int PIN_PX_CROSSING = 9;

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
    pinMode(PIN_DATA_WRITE, OUTPUT);
    pinMode(PIN_DATA_OUT, OUTPUT);
    pinMode(PIN_DATA_CLOCK, OUTPUT);
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
        digitalWrite(PIN_DATA_WRITE, LOW);
        shiftOut(PIN_DATA_OUT, PIN_DATA_CLOCK, MSBFIRST, light_state);
        digitalWrite(PIN_DATA_WRITE, HIGH);
        Serial.print("\n");
        Serial.print(light_state, BIN);
        Serial.print("\n");
    }
}
