#Requires AutoHotkey >=v2.0
#Include ../Libs/Gdip.ahk
CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

; ────── CONSTANTS ──────
global Pi := 3.14159265358979

; ────── DYNAMIC CONFIGURATION ──────

global Config := Map(
    "TargetColor", 0xffffb4,    ; Pixel RGB hex
    "WindowTitle", "Roblox",    ; Target window
    "FovSize", 250,             ; Square area (pixels)
    "ColorTolerance", 20,       ; Color detection tolerance
    "JitterAmount", 1,          ; Movement jitter
    "CurveAmpBase", 10,         ; Base curve amplitude (close)
    "CurveAmpMax", 25,          ; Max curve amplitude (far)
    "CurveFrequency", 0.15,     ; Curve frequency
    "StepDivBase", 2,           ; Base step divisor (far, faster)
    "StepDivMax", 6,            ; Max step divisor (close, slower)
    "MaxHistory", 8,            ; Prediction history size
    "PredictionFactor", 3,      ; Prediction multiplier
    "EaseConstant", 20,         ; Sigmoid easing constant
    "Size", 10                  ; Size of the target marker
)

global Step := 0
global LastTick := A_TickCount
global History := [], HistIndex := 0
global pressed := [false, false]
global ToX := 0, ToY := 0

Loop config["MaxHistory"] {
    History.Push({ x: 0, y: 0, t: 0 })
}

if !pToken := Gdip_Startup() {
    MsgBox "Gdip faild to Startup"
    return
}
OnExit onclose

Mon := GetPrimaryMonitor()
M := GetMonitorInfo(Mon)
WALeft := M.WALeft
WATop := M.WATop
WARight := M.WARight
WABottom := M.WABottom
WAWidth := M.WARight - M.WALeft
WAHeight := M.WABottom - M.WATop

Gui1 := Gui("-Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs")
Gui1.Show("NA")
hwnd1 := Gui1.Hwnd

hbm := CreateDIBSection(WAWidth, WAHeight)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(G, 4)

r1 := (Config["TargetColor"] >> 16) & 0xFF
g1 := (Config["TargetColor"] >> 8) & 0xFF
b1 := Config["TargetColor"] & 0xFF
alpha := 0x77  ; semi-transparent
oppositeColor := ((255 - r1) << 16) | ((255 - g1) << 8) | (255 - b1)  ; RGB
argbColor := (alpha << 24) | oppositeColor  ; ARGB as integer
pPen := Gdip_CreatePen(argbColor, Config["Size"] // 5)

SetTimer(Main, 1)
SetTimer(overlay, 1)

; ────── HOTKEYS ──────
F1:: ExitApp()
F2:: {
    global config
    MouseGetPos &x, &y
    config["TargetColor"] := PixelGetColor(x, y)
    ToolTip Format("Color: 0x{:06X}", config["TargetColor"]), 0, 0
}

; ────── MAIN LOGIC ──────
Main() {
    global History, HistIndex, Step, LastTick, pressed, Config, ToX, ToY

    hwnd := WinExist(config["WindowTitle"])
    if !hwnd || !(GetKeyState("LButton", "P") || GetKeyState("RButton", "P")) {
        return
    }

    ; Delta time calculation
    now := A_TickCount
    deltaTime := now - LastTick
    LastTick := now
    timeScale := deltaTime / 16  ; Normalize to 60 FPS baseline

    ; Client area center
    WinGetClientPos(&cx, &cy, &cw, &ch, hwnd)
    centerX := cx + cw // 2
    centerY := cy + ch // 2

    ; Define search area
    half := config["FovSize"] // 2
    x1 := centerX - half, y1 := centerY - half
    x2 := centerX + half, y2 := centerY + half

    ; Search for target pixel
    if !PixelSearch(&px, &py, x1, y1, x2, y2, config["TargetColor"], config["ColorTolerance"]) {
        return
    }

    ; Update history
    HistIndex := Mod(HistIndex + 1, config["MaxHistory"])
    History[HistIndex + 1] := { x: px, y: py, t: now }

    if HistIndex < 2 {
        return
    }

    ; Velocity prediction
    count := 0, totalDx := 0, totalDy := 0, totalDt := 0
    loopCount := Min(HistIndex, config["MaxHistory"] - 1)

    Loop loopCount {
        i := Mod(HistIndex - A_Index + config["MaxHistory"], config["MaxHistory"])
        j := Mod(i + 1, config["MaxHistory"])
        pt1 := History[i + 1], pt2 := History[j + 1]
        dt := pt2.t - pt1.t
        if (dt > 0) {
            totalDx += (pt2.x - pt1.x)
            totalDy += (pt2.y - pt1.y)
            totalDt += dt
            count += 1
        }
    }

    if (count = 0 || totalDt = 0) {
        return
    }

    ; Predict position
    vx := totalDx / totalDt
    vy := totalDy / totalDt
    dtAhead := 16 * config["PredictionFactor"]
    predX := Round(px + vx * dtAhead)
    predY := Round(py + vy * dtAhead)

    ; Calculate movement
    MouseGetPos(&mx, &my)
    dx := predX - mx
    dy := predY - my
    ToolTip "ΔX: " dx " ΔY: " dy, 0, 0

    ; Smoothing using sigmoid-style easing
    dist := Sqrt(dx ** 2 + dy ** 2)
    ease := dist / (dist + config["EaseConstant"])  ; Smooth factor between 0 and 1

    ; Dynamic parameters based on distance
    distanceFactor := Min(dist / config["FovSize"], 1.0) ; Normalize to 0-1
    stepDiv := config["StepDivMax"] - (config["StepDivMax"] - config["StepDivBase"]) * distanceFactor
    curveAmp := config["CurveAmpBase"] + (config["CurveAmpMax"] - config["CurveAmpBase"]) * distanceFactor

    ; Curve
    Step += 1
    curve := Sin(Step * config["CurveFrequency"]) * curveAmp
    angle := ATan2(dy, dx)
    offsetX := curve * Cos(angle + Pi / 2)
    offsetY := curve * Sin(angle + Pi / 2)

    ; Jitter
    jitterX := Random(-config["JitterAmount"], config["JitterAmount"])
    jitterY := Random(-config["JitterAmount"], config["JitterAmount"])

    ; Rare overshoot or micro jerk
    if Random(1, 100) <= 3 {
        offsetX += dx * 0.05
        offsetY += dy * 0.05
    }
    if Random(1, 100) <= 2 {
        jitterX += Random(-1, 1)
        jitterY += Random(-1, 1)
    }

    ; Final movement calculation
    rawMoveX := (dx + offsetX + jitterX) * ease * timeScale / stepDiv
    rawMoveY := (dy + offsetY + jitterY) * ease * timeScale / stepDiv

    ; Clamp to stay within FOV radius
    newX := mx + rawMoveX
    newY := my + rawMoveY
    dFov := Config["FovSize"] // 2
    clampedX := clamp(newX, centerX - dFov, centerX + dFov)
    clampedY := clamp(newY, centerY - dFov, centerY + dFov)

    moveX := Ceil(clampedX - mx)
    moveY := Ceil(clampedY - my)


    ; Execute movement
    ToX := clampedX
    ToY := clampedY
    DllCall("mouse_event", "uint", 0x0001, "int", moveX, "int", moveY, "uint", 0, "ptr", 0)
}

; ────── OVERLAY ──────
overlay() {
    global hdc, hbm, obm, G, pPen, hwnd1, Config, ToX, ToY
    hwnd := WinExist(config["WindowTitle"])
    if !hwnd {
        return
    }

    WinGetClientPos(&X, &Y, &W, &H, hwnd)
    centerX := (W // 2) + X
    centerY := (H // 2) + Y
    half := Config["FovSize"] // 2
    sizeH := Config["Size"] // 2
    size := 16
    r := size // 2

    ; Gdip_DrawRoundedRectangle(G, pPen, ToX - r, ToY - r, size, size, 3)
    Gdip_DrawRectangle(G, pPen, centerX - half - sizeH, centerY - half - sizeH, Config["FovSize"] + sizeH, Config["FovSize"] + sizeH)

    UpdateLayeredWindow(hwnd1, hdc, WALeft, WATop, WAWidth, WAHeight)
    Gdip_GraphicsClear(G)
}

; ────── UTILITY ──────
ATan2(y, x) {
    return DllCall("msvcrt.dll\atan2", "double", y, "double", x, "cdecl double")
}

clamp(value, min, max) {
    return (value < min) ? min : (value > max) ? max : value
}

onclose(*) {
    global

    SelectObject(hdc, obm)
    DeleteObject(hbm)
    DeleteDC(hdc)
    if pPen {
        Gdip_DeletePen(pPen)
    }
    if G {
        Gdip_DeleteGraphics(G)
    }
    if pToken {
        Gdip_Shutdown(pToken)
    }
}