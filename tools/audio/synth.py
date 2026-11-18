#!/usr/bin/env python3
"""Synthesises every sound in UNWRIT. No samples, no libraries.

    python3 tools/audio/synth.py            # all sounds into game/assets/sfx
    python3 tools/audio/synth.py parry toll # only these

Every sound is built from sines, noise and one-pole filters, so the whole
soundscape is ours and can be rebuilt from this file.
"""
import math
import os
import random
import struct
import sys
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "sfx")
TAU = math.tau


def n(seconds):
    return int(SR * seconds)


def silence(seconds):
    return [0.0] * n(seconds)


def noise(seconds, seed=1):
    r = random.Random(seed)
    return [r.uniform(-1.0, 1.0) for _ in range(n(seconds))]


def lowpass(x, cutoff):
    """cutoff may be a number or a function of 0..1 progress."""
    out = []
    y = 0.0
    m = len(x)
    for i, v in enumerate(x):
        c = cutoff(i / m) if callable(cutoff) else cutoff
        a = 1.0 - math.exp(-TAU * c / SR)
        y += a * (v - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [a - b for a, b in zip(x, lp)]


def bandpass(x, lo, hi):
    return highpass(lowpass(x, hi), lo)


def tone(seconds, freq, shape="sine", phase=0.0):
    """freq may be a number or a function of 0..1 progress."""
    out = []
    ph = phase
    m = n(seconds)
    for i in range(m):
        f = freq(i / m) if callable(freq) else freq
        ph += TAU * f / SR
        if shape == "sine":
            out.append(math.sin(ph))
        elif shape == "saw":
            out.append(((ph / TAU) % 1.0) * 2.0 - 1.0)
        elif shape == "square":
            out.append(1.0 if math.sin(ph) >= 0 else -1.0)
        else:
            out.append(2.0 * abs(((ph / TAU) % 1.0) * 2.0 - 1.0) - 1.0)
    return out


def env(x, attack=0.005, decay=None, curve=3.0, hold=0.0):
    """Fast attack, exponential decay over the rest."""
    m = len(x)
    a = max(1, n(attack))
    h = n(hold)
    out = []
    for i, v in enumerate(x):
        if i < a:
            g = i / a
        elif i < a + h:
            g = 1.0
        else:
            t = (i - a - h) / max(1, m - a - h)
            g = math.exp(-curve * t) * (1.0 - t)
        out.append(v * g)
    return out


def swell(x, peak=0.5, power=1.5):
    """Rises to a peak then falls: for breaths and pads."""
    m = len(x)
    out = []
    for i, v in enumerate(x):
        t = i / m
        g = (t / peak) ** power if t < peak else ((1.0 - t) / (1.0 - peak)) ** power
        out.append(v * g)
    return out


def mix(*tracks):
    m = max(len(t) for t in tracks)
    out = [0.0] * m
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def gain(x, g):
    return [v * g for v in x]


def at(x, seconds):
    return silence(seconds) + x


def partials(seconds, base, ratios, decays, amps=None, detune=0.0):
    """A struck thing: several sines, each dying at its own rate."""
    m = n(seconds)
    out = [0.0] * m
    for k, ratio in enumerate(ratios):
        f = base * ratio * (1.0 + detune * (k % 3 - 1))
        d = decays[k % len(decays)]
        a = amps[k % len(amps)] if amps else 1.0 / (k + 1)
        w = TAU * f / SR
        for i in range(m):
            out[i] += a * math.sin(w * i) * math.exp(-i / (SR * d))
    return out


def normalise(x, peak=0.85):
    top = max(1e-9, max(abs(v) for v in x))
    return [v * peak / top for v in x]


def fade_edges(x, seconds=0.004):
    m = min(n(seconds), len(x) // 2)
    for i in range(m):
        g = i / m
        x[i] *= g
        x[-1 - i] *= g
    return x


def loopable(x, cross):
    """Folds the tail over the head so the end meets the start."""
    c = n(cross)
    body = len(x) - c
    out = x[:body]
    for i in range(c):
        t = i / c
        out[i] = x[i] * t + x[body + i] * (1.0 - t)
    return out


def write(name, x, peak=0.85, loop=False):
    x = normalise(x, peak)
    if not loop:
        x = fade_edges(x)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in x))
    print("  %-16s %.2fs" % (name, len(x) / SR))


BELL = [0.5, 1.0, 1.19, 1.5, 2.0, 2.51, 2.66, 3.01, 4.1]
CLANG = [1.0, 1.52, 2.29, 2.99, 3.71, 4.63]


def sweep(a, b):
    return lambda t: a + (b - a) * t


def exp_sweep(a, b):
    return lambda t: a * (b / a) ** t


def s_whoosh():
    x = noise(0.2, 2)
    x = bandpass(x, exp_sweep(500, 1800), exp_sweep(1500, 5000))
    return swell(x, 0.45, 1.6)


def s_whoosh_heavy():
    x = noise(0.34, 3)
    x = bandpass(x, exp_sweep(160, 700), exp_sweep(600, 2600))
    return mix(swell(x, 0.5, 1.4), gain(env(tone(0.3, exp_sweep(90, 45)), 0.04, curve=3), 0.5))


def s_hit():
    thump = env(tone(0.14, exp_sweep(190, 70)), 0.002, curve=5)
    crack = env(lowpass(noise(0.1, 4), 2600), 0.001, curve=7)
    return mix(thump, gain(crack, 0.8))


def s_hit_heavy():
    thump = env(tone(0.3, exp_sweep(140, 42)), 0.002, curve=4)
    crunch = env(lowpass(noise(0.22, 5), 1800), 0.001, curve=5)
    snap = env(highpass(noise(0.05, 6), 3000), 0.001, curve=8)
    return mix(thump, gain(crunch, 0.9), gain(snap, 0.4))


def s_parry():
    ring = partials(0.7, 1750, CLANG, [0.22, 0.16, 0.12, 0.09, 0.07, 0.05], [1, 0.8, 0.7, 0.5, 0.4, 0.3], 0.003)
    click = env(highpass(noise(0.03, 7), 4000), 0.0005, curve=9)
    return mix(ring, gain(click, 1.2))


def s_block():
    ring = partials(0.22, 520, CLANG, [0.05, 0.04, 0.03, 0.025], [1, 0.7, 0.5, 0.3])
    thud = env(lowpass(noise(0.08, 8), 1200), 0.001, curve=7)
    return mix(ring, thud)


def s_break():
    crack = env(highpass(noise(0.35, 9), 1800), 0.001, curve=4)
    fall = env(tone(0.45, exp_sweep(900, 140), "tri"), 0.002, curve=3)
    ring = partials(0.5, 900, CLANG, [0.12, 0.09, 0.06], [0.6, 0.5, 0.3])
    return mix(crack, gain(fall, 0.7), ring)


def s_dash():
    x = bandpass(noise(0.18, 10), exp_sweep(1200, 4000), exp_sweep(3000, 9000))
    return swell(x, 0.3, 1.3)


def s_slip():
    a = tone(0.26, exp_sweep(900, 2400))
    b = tone(0.26, exp_sweep(1350, 3600))
    return swell(mix(a, gain(b, 0.5)), 0.6, 2.0)


def s_step():
    return env(lowpass(noise(0.07, 11), 700), 0.002, curve=6)


def s_jump():
    return swell(bandpass(noise(0.14, 12), exp_sweep(300, 1400), exp_sweep(900, 3600)), 0.6, 1.4)


def s_land():
    return mix(env(tone(0.12, exp_sweep(110, 50)), 0.002, curve=5), gain(env(lowpass(noise(0.1, 13), 900), 0.002, curve=6), 0.8))


def s_bolt():
    carrier = tone(0.3, exp_sweep(1300, 320), "tri")
    wob = tone(0.3, 38)
    x = [c * (0.6 + 0.4 * w) for c, w in zip(carrier, wob)]
    return env(mix(x, gain(highpass(noise(0.3, 14), 3500), 0.25)), 0.004, curve=3.5)


def s_cast():
    a = tone(0.34, exp_sweep(380, 1500))
    b = tone(0.34, exp_sweep(570, 2250))
    return swell(mix(a, gain(b, 0.6), gain(highpass(noise(0.34, 15), 4000), 0.15)), 0.75, 1.6)


def s_toll():
    bell = partials(2.6, 124, BELL, [1.6, 1.3, 1.0, 0.8, 0.6, 0.45, 0.4, 0.3, 0.2], [0.9, 1, 0.7, 0.6, 0.5, 0.35, 0.3, 0.25, 0.15], 0.002)
    strike = env(lowpass(noise(0.06, 16), 3000), 0.001, curve=6)
    return mix(bell, gain(strike, 0.8))


def s_slam():
    boom = env(tone(0.8, exp_sweep(95, 30)), 0.003, curve=3.5)
    rumble = env(lowpass(noise(0.7, 17), 500), 0.003, curve=3)
    crack = env(bandpass(noise(0.12, 18), 800, 4000), 0.001, curve=7)
    return mix(boom, rumble, gain(crack, 0.6))


def s_growl():
    saw = tone(0.55, sweep(88, 70), "saw")
    am = tone(0.55, 27)
    x = [s * (0.55 + 0.45 * a) for s, a in zip(saw, am)]
    x = lowpass(mix(x, gain(noise(0.55, 19), 0.35)), sweep(1400, 500))
    return swell(x, 0.3, 1.2)


def s_roar():
    saw = mix(tone(1.9, sweep(62, 44), "saw"), gain(tone(1.9, sweep(93, 66), "saw"), 0.6))
    am = tone(1.9, 21)
    x = [s * (0.5 + 0.5 * a) for s, a in zip(saw, am)]
    x = lowpass(mix(x, gain(noise(1.9, 20), 0.5)), lambda t: 500 + 1700 * math.sin(math.pi * t) ** 2)
    bell = gain(partials(1.9, 62, BELL, [1.2, 1.0, 0.8, 0.6], [0.5, 0.5, 0.3, 0.2]), 0.5)
    return mix(swell(x, 0.25, 1.1), bell)


def s_death():
    a = env(tone(0.8, exp_sweep(420, 60), "tri"), 0.01, curve=3)
    b = lowpass(noise(0.8, 21), exp_sweep(5000, 300))
    return mix(a, gain(swell(b, 0.15, 1.5), 0.7))


def s_warn():
    a = env(tone(0.09, 1900, "square"), 0.001, curve=4)
    b = at(env(tone(0.12, 2500, "square"), 0.001, curve=4), 0.07)
    return lowpass(mix(a, b), 5000)


def s_release_charge():
    rise = tone(1.0, exp_sweep(70, 520), "saw")
    rise = lowpass(rise, exp_sweep(300, 4000))
    air = bandpass(noise(1.0, 22), exp_sweep(200, 2000), exp_sweep(800, 8000))
    x = mix(rise, gain(air, 0.8))
    m = len(x)
    return [v * (i / m) ** 2 for i, v in enumerate(x)]


def s_release():
    boom = env(tone(1.4, exp_sweep(110, 28)), 0.002, curve=3)
    blast = env(lowpass(noise(1.0, 23), exp_sweep(6000, 400)), 0.001, curve=3.5)
    chord = mix(*[gain(partials(2.2, f, [1, 2, 3, 4.02], [1.0, 0.7, 0.5, 0.3], [1, 0.5, 0.3, 0.2]), 0.5) for f in (220, 329.6, 440, 554.4)])
    chord = env(chord, 0.02, curve=1.5)
    return mix(boom, blast, gain(chord, 0.8))


def s_seal():
    return swell(mix(tone(0.55, exp_sweep(640, 190)), gain(tone(0.55, exp_sweep(960, 285)), 0.4)), 0.2, 1.5)


def s_special():
    chord = mix(*[partials(0.7, f, [1, 2, 3.01], [0.3, 0.2, 0.12], [1, 0.6, 0.3]) for f in (392, 587.3, 784)])
    zing = env(highpass(noise(0.2, 24), 5000), 0.001, curve=5)
    return mix(chord, gain(zing, 0.6), gain(env(tone(0.3, exp_sweep(200, 60)), 0.002, curve=4), 0.8))


def s_sever():
    air = bandpass(noise(0.3, 25), exp_sweep(2000, 600), exp_sweep(9000, 2500))
    zing = partials(0.5, 2400, CLANG, [0.15, 0.1, 0.08], [0.7, 0.5, 0.4])
    return mix(swell(air, 0.2, 1.3), at(zing, 0.1))


def s_guard():
    hum = mix(tone(0.5, 147), gain(tone(0.5, 220.5), 0.6), gain(tone(0.5, 294), 0.4))
    return swell(hum, 0.25, 1.4)


def s_devour():
    parts = []
    for k, t in enumerate((0.0, 0.16, 0.3)):
        crunch = env(lowpass(noise(0.14, 26 + k), 900 + 300 * k), 0.002, curve=5)
        parts.append(at(crunch, t))
    gulp = at(env(tone(0.35, exp_sweep(180, 55)), 0.02, curve=3), 0.3)
    wet = at(env(bandpass(noise(0.3, 30), 300, 1500), 0.01, curve=4), 0.1)
    return mix(*parts, gulp, gain(wet, 0.5))


def chime(freq, seconds=1.0, delay=0.0):
    return at(partials(seconds, freq, [1, 2.0, 3.0, 4.2], [seconds * 0.4, seconds * 0.25, seconds * 0.15, seconds * 0.1], [1, 0.4, 0.2, 0.1]), delay)


def s_send():
    return mix(chime(523.3, 1.0), chime(659.3, 1.0, 0.13), chime(784.0, 1.2, 0.26), gain(swell(highpass(noise(1.2, 31), 5000), 0.3, 2.0), 0.15))


def s_relic():
    return mix(chime(880, 1.4), chime(1318.5, 1.4, 0.18), gain(chime(1760, 1.2, 0.36), 0.6))


def s_anvil():
    """Three hammer strikes on hot steel, then the hiss of the quench."""
    parts = []
    for i, t in enumerate([0.0, 0.32, 0.64]):
        strike = mix(env(highpass(noise(0.08, 20 + i), 2500), 0.001, curve=6),
                     partials(0.6, 620 + 30 * i, CLANG, [0.18, 0.12, 0.08], [0.8, 0.5, 0.3]))
        parts.append(at(gain(strike, 1.0 - 0.15 * i), t))
    hiss = at(gain(swell(bandpass(noise(0.9, 31), 2500, 7000), 0.15, 2.0), 0.35), 1.05)
    return mix(*parts, hiss)


def s_socket():
    click = env(highpass(noise(0.05, 41), 3000), 0.001, curve=7)
    return mix(click, gain(chime(1046.5, 0.7, 0.03), 0.7), gain(chime(1568, 0.6, 0.08), 0.4))


def s_crit():
    """The critical's tell: steel drawn and ringing, rising."""
    shing = env(bandpass(noise(0.5, 61), 3500, 9000), 0.004, curve=3)
    ring = partials(0.7, 1180, CLANG, [0.3, 0.22, 0.16], [0.5, 0.35, 0.2])
    rise = env(tone(0.45, exp_sweep(600, 1800), "tri"), 0.01, curve=2)
    return mix(gain(shing, 0.6), ring, gain(rise, 0.25))


def s_evasive():
    """Bursting out of a combo: a gust and a low thump."""
    gust = swell(bandpass(noise(0.45, 62), 400, 3000), 0.15, 1.8)
    thump = env(tone(0.25, exp_sweep(160, 50)), 0.002, curve=4)
    return mix(gust, gain(thump, 0.8))


def s_grab():
    """Caught: a growl under a creak of bone."""
    saw = tone(0.6, sweep(70, 55), "saw")
    am = tone(0.6, 18)
    gr = lowpass([a * (0.6 + 0.4 * b) for a, b in zip(saw, am)], 700)
    creak = env(bandpass(noise(0.4, 63), 900, 2400), 0.02, curve=2)
    return mix(swell(gr, 0.25, 1.5), gain(creak, 0.5))


def s_body():
    """A body hitting the ground or a wall."""
    thud = env(tone(0.35, exp_sweep(110, 38)), 0.002, curve=4)
    dirt = env(lowpass(noise(0.3, 64), 1200), 0.001, curve=5)
    return mix(thud, gain(dirt, 0.7))


def s_finisher():
    """The last cut of a string: a crack, then a boom."""
    crack = env(highpass(noise(0.12, 65), 2500), 0.001, curve=6)
    boom = env(tone(0.6, exp_sweep(130, 34)), 0.003, curve=3.5)
    ring = partials(0.5, 640, CLANG, [0.15, 0.1, 0.08], [0.4, 0.3, 0.2])
    return mix(crack, boom, gain(ring, 0.6))


def s_knocked():
    """Dropped to the knees: a thud and a breath let out."""
    thud = env(tone(0.25, exp_sweep(120, 60)), 0.002, curve=4)
    breath = at(swell(bandpass(noise(0.4, 66), 500, 2200), 0.2, 1.6), 0.08)
    return mix(thud, gain(breath, 0.5))


def s_rift():
    """The world tearing: a drone that rises through noise."""
    drone = lowpass(tone(1.8, exp_sweep(45, 90), "saw"), 600)
    tear = swell(bandpass(noise(1.8, 67), 300, 4000), 0.6, 1.4)
    return mix(swell(drone, 0.5, 1.2), gain(tear, 0.7))


def s_horn():
    """An event's horn: two low notes, a fifth apart."""
    a = swell(lowpass(tone(1.4, 98, "saw"), 900), 0.35, 1.3)
    b = at(swell(lowpass(tone(1.1, 147, "saw"), 900), 0.35, 1.3), 0.25)
    return mix(a, gain(b, 0.8))


def s_quest():
    return mix(chime(659.3, 0.6), chime(880, 0.7, 0.1))


def s_quest_done():
    return mix(chime(523.3, 0.7), chime(659.3, 0.7, 0.1), chime(784, 0.7, 0.2), chime(1046.5, 1.0, 0.3))


def s_air_jump():
    gust = swell(bandpass(noise(0.25, 68), 800, 5000), 0.2, 2.0)
    return gain(gust, 0.8)


def s_levelup():
    return mix(chime(392, 0.9), chime(523.3, 0.9, 0.11), chime(659.3, 0.9, 0.22), chime(784, 1.2, 0.33))


def s_ui_tick():
    return env(tone(0.035, 1400, "tri"), 0.001, curve=5)


def s_ui_open():
    return mix(chime(440, 0.3), gain(chime(660, 0.3, 0.03), 0.6))


def s_breath_in():
    x = bandpass(noise(1.3, 32), exp_sweep(300, 900), exp_sweep(900, 3000))
    return swell(x, 0.75, 1.6)


def s_breath_out():
    x = bandpass(noise(1.5, 33), exp_sweep(800, 250), exp_sweep(2600, 700))
    return swell(x, 0.2, 1.4)


def s_rest():
    chord = mix(*[gain(tone(1.8, f), a) for f, a in ((146.8, 1), (220, 0.8), (293.7, 0.6), (369.9, 0.5), (440, 0.4))])
    return swell(chord, 0.35, 1.6)


def s_write():
    gong = partials(3.2, 82, BELL, [2.0, 1.7, 1.4, 1.1, 0.9, 0.7, 0.6, 0.5, 0.3], [1, 0.9, 0.7, 0.6, 0.5, 0.4, 0.3, 0.25, 0.2], 0.003)
    choir = mix(*[gain(tone(3.2, f * (1.0 + 0.003 * k)), 0.3) for k, f in enumerate((164.8, 246.9, 329.6, 415.3, 493.9))])
    choir = swell(choir, 0.3, 1.3)
    return mix(gong, gain(choir, 0.9), gain(env(lowpass(noise(0.3, 34), 2000), 0.001, curve=5), 0.6))


def s_wind():
    seconds = 9.0
    base = noise(seconds, 35)
    low = lowpass(base, lambda t: 260 + 160 * math.sin(TAU * t * 2.0) + 90 * math.sin(TAU * t * 5.0 + 1.0))
    high = bandpass(noise(seconds, 36), 900, 2400)
    m = len(low)
    hiss = [h * (0.12 + 0.1 * math.sin(TAU * i / m * 3.0 + 2.0)) for i, h in enumerate(high)]
    body = [v * (0.75 + 0.25 * math.sin(TAU * i / m * 1.0)) for i, v in enumerate(low)]
    return loopable(mix(body, hiss), 1.0)


def s_rain():
    """Steady rain: a bright hiss over a soft roar, with drops ticking on it."""
    seconds = 8.0
    r = random.Random(91)
    hiss = bandpass(noise(seconds, 92), 1800, 6000)
    roar = lowpass(noise(seconds, 93), 500)
    m = len(hiss)
    out = [h * 0.35 + w * 0.55 for h, w in zip(hiss, roar)]
    for i in range(420):
        at_i = r.randrange(0, m - 400)
        amp = r.uniform(0.05, 0.22)
        f = r.uniform(2500, 5200)
        for k in range(300):
            out[at_i + k] += amp * math.exp(-k / 40.0) * math.sin(TAU * f * k / SR)
    return loopable(out, 1.0)


def s_spark():
    """An electric snap that jumps to a second target."""
    r = random.Random(97)
    out = silence(0.32)
    for k in range(5):
        burst = env(highpass(noise(0.05, 98 + k), 2500), 0.001, 0.04)
        start = int(r.uniform(0.0, 0.2) * SR)
        for i, v in enumerate(burst):
            if start + i < len(out):
                out[start + i] += v * r.uniform(0.5, 1.0)
    zap = env(tone(0.25, 1400, "saw"), 0.002, 0.2)
    return mix(out, gain(zap, 0.25))


def s_thunder():
    """A crack overhead, then a long rolling rumble."""
    seconds = 3.6
    crack = env(highpass(noise(0.25, 94), 900), 0.002, 0.18)
    rumble = lowpass(noise(seconds, 95), lambda t: 140 - 90 * t)
    m = len(rumble)
    rumble = [v * (math.exp(-3.0 * i / m) * (0.7 + 0.3 * math.sin(TAU * i / m * 6.0))) for i, v in enumerate(rumble)]
    return mix(gain(crack, 0.8), at(rumble, 0.03))


def pad(seconds, freqs, lfo_rate):
    m = n(seconds)
    out = [0.0] * m
    for k, f in enumerate(freqs):
        w1 = TAU * f / SR
        w2 = TAU * f * 1.004 / SR
        ph = k * 1.7
        lw = TAU * lfo_rate * (1.0 + 0.23 * k) / SR
        for i in range(m):
            g = 0.5 + 0.5 * math.sin(lw * i + ph)
            out[i] += (math.sin(w1 * i) + math.sin(w2 * i + 1.0)) * g / (k + 1.5)
    return out


def s_music_pale():
    """The Shelf: a low drone, a slow minor pad, a far bell now and then."""
    seconds = 34.0
    drone = pad(seconds, [73.42, 110.0, 146.83], 0.031)
    air = pad(seconds, [293.66, 349.23, 440.0], 0.047)
    bells = silence(seconds)
    r = random.Random(40)
    notes = [587.33, 698.46, 880.0, 523.25, 783.99]
    t = 2.0
    while t < seconds - 6.0:
        b = gain(chime(r.choice(notes), 4.0), r.uniform(0.25, 0.5))
        start = n(t)
        for i, v in enumerate(b):
            if start + i < len(bells):
                bells[start + i] += v
        t += r.uniform(3.5, 7.0)
    return loopable(mix(drone, gain(air, 0.35), gain(bells, 0.9)), 2.0)


def drum(freq, seconds=0.35, noise_amt=0.4, seed=1):
    body = env(tone(seconds, exp_sweep(freq * 2.2, freq)), 0.002, curve=5)
    skin = env(lowpass(noise(seconds * 0.5, seed), 1500), 0.001, curve=7)
    return mix(body, gain(skin, noise_amt))


def s_music_fight():
    """A great enemy: war drums in seven, a pulsing bass, a tolling bell."""
    beat = 60.0 / 132.0
    bars = 8
    per_bar = 7
    seconds = beat * per_bar * bars + 2.0
    out = silence(seconds)

    def put(x, t, g=1.0):
        s = n(t)
        for i, v in enumerate(x):
            if s + i < len(out):
                out[s + i] += v * g

    low = drum(52, 0.5, 0.3, 41)
    mid = drum(92, 0.3, 0.5, 42)
    tick = env(highpass(noise(0.05, 43), 4000), 0.001, curve=8)
    pattern = [1, 0, 2, 0, 1, 2, 2]
    for bar in range(bars):
        for b in range(per_bar):
            t = (bar * per_bar + b) * beat
            hit = pattern[b]
            if hit == 1:
                put(low, t, 1.0)
            elif hit == 2:
                put(mid, t, 0.7)
            put(tick, t + beat * 0.5, 0.25)
            root = 55.0 if bar % 4 < 2 else (49.0 if bar % 4 == 2 else 61.74)
            bass = env(lowpass(tone(beat * 0.9, root, "saw"), 420), 0.004, curve=2.5)
            put(bass, t, 0.55)
        if bar % 2 == 0:
            put(partials(3.0, 110, BELL, [1.4, 1.1, 0.9, 0.7, 0.5], [0.8, 1, 0.6, 0.5, 0.4]), bar * per_bar * beat, 0.5)
    drone = pad(seconds, [55.0, 82.41], 0.11)
    return loopable(mix(out, gain(drone, 0.25)), 2.0)


def s_music_inner():
    """The Stillness: glass tones that beat slowly against each other."""
    seconds = 26.0
    a = pad(seconds, [196.0, 293.66, 392.0, 587.33], 0.05)
    b = pad(seconds, [98.0, 146.83], 0.027)
    high = pad(seconds, [1174.66, 1567.98], 0.09)
    return loopable(mix(a, gain(b, 0.8), gain(high, 0.12)), 2.0)



def place_into(out, x, t, g=1.0):
    st = n(t)
    for i, v in enumerate(x):
        if st + i < len(out):
            out[st + i] += v * g


def pluck(freq, seconds=1.6):
    """A plucked string: bright attack, quick fall, a little body."""
    body = partials(seconds, freq, [1, 2.0, 3.01, 4.0, 5.02], [seconds * 0.35, seconds * 0.2, seconds * 0.12, seconds * 0.08, seconds * 0.05], [1, 0.55, 0.35, 0.2, 0.1])
    pick = env(highpass(noise(0.02, int(freq) % 97 + 3), 2500), 0.0005, curve=9)
    return mix(body, gain(pick, 0.3))


def s_music_town():
    """Calder Town by day: a soft major pad and a slow wandering melody."""
    seconds = 32.0
    out = silence(seconds)
    chords = [[261.6, 329.6, 392.0], [220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7]]
    for k, ch in enumerate(chords):
        place_into(out, swell(pad(8.4, ch, 0.07), 0.3, 1.2), 8.0 * k, 0.5)
        place_into(out, swell(pad(8.4, [ch[0] * 0.5], 0.05), 0.3, 1.2), 8.0 * k, 0.4)
    scale = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5]
    r = random.Random(81)
    t = 0.5
    note = 2
    while t < seconds - 2.0:
        note = max(0, min(len(scale) - 1, note + r.choice([-2, -1, -1, 1, 1, 2])))
        place_into(out, chime(scale[note], 2.2), t, r.uniform(0.25, 0.4))
        t += r.choice([0.5, 1.0, 1.0, 1.5])
    return loopable(out, 2.0)


def s_music_citadel():
    """The Citadel: a low drone and slow plucked strings in a minor key."""
    seconds = 34.0
    out = silence(seconds)
    place_into(out, pad(seconds, [73.4, 110.0], 0.03), 0.0, 0.55)
    scale = [293.7, 349.2, 392.0, 440.0, 523.3, 587.3]
    phrase = [0, 2, 3, 2, 4, 3, 1, 0, 2, 3, 5, 4, 3, 2, 1, 0]
    beat = 2.0
    for i, k in enumerate(phrase):
        place_into(out, pluck(scale[k], 2.4), 1.0 + beat * i, 0.55)
        if i % 4 == 0:
            place_into(out, pluck(scale[k] * 0.5, 3.0), 1.0 + beat * i, 0.35)
    for t in (0.0, 16.0):
        place_into(out, partials(6.0, 98.0, BELL, [2.0, 1.6, 1.2, 0.9, 0.6], [0.6, 0.8, 0.5, 0.4, 0.3]), t, 0.35)
    return loopable(out, 2.0)


def s_music_stacks():
    """The Stacks: a low, dusty pad under slow wooden plucks, like an archive breathing."""
    seconds = 32.0
    out = silence(seconds)
    place_into(out, pad(seconds, [98.0, 146.8, 196.0, 233.1], 0.04), 0.0, 0.5)
    place_into(out, pad(seconds, [587.3, 784.0], 0.09), 0.0, 0.05)
    scale = [293.7, 349.2, 392.0, 466.2, 587.3]
    r = random.Random(57)
    t = 1.5
    while t < seconds - 3.0:
        f = r.choice(scale)
        pluck = partials(1.4, f, [1.0, 2.76, 5.4], [0.5, 0.25, 0.1], [0.6, 0.25, 0.1])
        place_into(out, pluck, t, r.uniform(0.18, 0.3))
        if r.random() < 0.3:
            place_into(out, partials(1.4, f * 0.5, [1.0, 2.76], [0.6, 0.3], [0.5, 0.2]), t + 0.25, 0.15)
        t += r.uniform(1.6, 3.2)
    return loopable(out, 2.0)


def s_music_reach():
    """The Silver Reach: high glass bells over a cold, shimmering pad."""
    seconds = 30.0
    out = silence(seconds)
    place_into(out, pad(seconds, [146.8, 220.0, 293.7, 440.0], 0.06), 0.0, 0.45)
    place_into(out, pad(seconds, [1174.7, 1760.0], 0.13), 0.0, 0.08)
    scale = [880.0, 987.8, 1174.7, 1318.5, 1760.0]
    r = random.Random(91)
    t = 1.0
    while t < seconds - 3.0:
        f = r.choice(scale)
        place_into(out, chime(f, 3.0), t, r.uniform(0.2, 0.35))
        place_into(out, chime(f * 1.5, 2.0), t + 0.12, 0.1)
        t += r.uniform(1.2, 2.6)
    return loopable(out, 2.0)


def s_music_deep():
    """The Undermark: a slow iron drum, a low growl of a drone, chains."""
    seconds = 32.0
    out = silence(seconds)
    place_into(out, pad(seconds, [41.2, 61.7, 82.4], 0.04), 0.0, 0.6)
    beat = 2.0
    for i in range(16):
        place_into(out, drum(44, 0.9, 0.5, 70 + i), beat * i, 1.0)
        if i % 4 == 3:
            place_into(out, drum(70, 0.4, 0.6, 90 + i), beat * i + 1.0, 0.6)
    r = random.Random(77)
    for i in range(10):
        clank = partials(1.2, r.uniform(380, 620), CLANG, [0.3, 0.2, 0.15, 0.1], [0.6, 0.5, 0.35, 0.2])
        place_into(out, clank, r.uniform(0.0, seconds - 2.0), 0.18)
    return loopable(out, 2.0)


SOUNDS = {
    "whoosh": (s_whoosh, 0.7), "whoosh_heavy": (s_whoosh_heavy, 0.8), "hit": (s_hit, 0.85),
    "hit_heavy": (s_hit_heavy, 0.9), "parry": (s_parry, 0.85), "block": (s_block, 0.75),
    "break": (s_break, 0.85), "dash": (s_dash, 0.6), "slip": (s_slip, 0.5), "step": (s_step, 0.6),
    "jump": (s_jump, 0.5), "land": (s_land, 0.7), "bolt": (s_bolt, 0.6), "cast": (s_cast, 0.6),
    "toll": (s_toll, 0.9), "slam": (s_slam, 0.95), "growl": (s_growl, 0.7), "roar": (s_roar, 0.9),
    "death": (s_death, 0.7), "warn": (s_warn, 0.5), "release_charge": (s_release_charge, 0.8),
    "release": (s_release, 0.95), "seal": (s_seal, 0.5), "special": (s_special, 0.8),
    "sever": (s_sever, 0.7), "guard": (s_guard, 0.6), "devour": (s_devour, 0.8), "send": (s_send, 0.6),
    "relic": (s_relic, 0.6), "levelup": (s_levelup, 0.65), "ui_tick": (s_ui_tick, 0.4),
    "ui_open": (s_ui_open, 0.5), "breath_in": (s_breath_in, 0.5), "breath_out": (s_breath_out, 0.5),
    "rest": (s_rest, 0.6), "write": (s_write, 0.9), "anvil": (s_anvil, 0.85), "socket": (s_socket, 0.55),
    "crit": (s_crit, 0.75), "evasive": (s_evasive, 0.7), "grab": (s_grab, 0.8), "body": (s_body, 0.8),
    "finisher": (s_finisher, 0.9), "knocked": (s_knocked, 0.65), "rift": (s_rift, 0.8), "horn": (s_horn, 0.75),
    "quest": (s_quest, 0.5), "quest_done": (s_quest_done, 0.55), "air_jump": (s_air_jump, 0.5),
    "thunder": (s_thunder, 0.95), "spark": (s_spark, 0.7),
}
LOOPS = {
    "wind": (s_wind, 0.6), "rain": (s_rain, 0.55), "music_pale": (s_music_pale, 0.7),
    "music_fight": (s_music_fight, 0.8), "music_inner": (s_music_inner, 0.7),
    "music_town": (s_music_town, 0.6), "music_citadel": (s_music_citadel, 0.65), "music_reach": (s_music_reach, 0.6), "music_stacks": (s_music_stacks, 0.6), "music_deep": (s_music_deep, 0.7),
}


def main():
    want = sys.argv[1:]
    for name, (fn, peak) in SOUNDS.items():
        if not want or name in want:
            write(name, fn(), peak)
    for name, (fn, peak) in LOOPS.items():
        if not want or name in want:
            write(name, fn(), peak, loop=True)


if __name__ == "__main__":
    main()
