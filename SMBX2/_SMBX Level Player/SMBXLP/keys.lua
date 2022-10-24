--[[
  Library made by yonderboi
  Modified by Yoshi021
]]

local Keys = {}
Keys.type = {}

function Keys.getName(name, num)
  if Keys.type[name] then
    return Keys.type[name][num] or "Unknown Key"
  else
    return "Unknown Button"
  end
end

revkeyboard = {}
revkeyboard["Pause Key"] = 0
revkeyboard.LButton = 1
revkeyboard.RButton = 2
revkeyboard.Cancel = 3
revkeyboard.MButton = 4
revkeyboard.XButton1 = 5
revkeyboard.XButton2 = 6
revkeyboard.Back = 8
revkeyboard.Tab = 9
revkeyboard.LineFeed = 10
revkeyboard.Clear = 12
revkeyboard.Return = 13
revkeyboard.ShiftKey = 16
revkeyboard.ControlKey = 17
revkeyboard.Menu = 18
revkeyboard.Pause = 19
revkeyboard.Capital = 20
revkeyboard.KanaMode = 21
revkeyboard.JunjaMode = 23
revkeyboard.FinalMode = 24
revkeyboard.HanjaMode = 25
revkeyboard.Escape = 27
revkeyboard.IMEConvert = 28
revkeyboard.IMENonconvert = 29
revkeyboard.IMEAceept = 30
revkeyboard.IMEModeChange = 31
revkeyboard.Space = 32
revkeyboard.PageUp = 33
revkeyboard.Next = 34
revkeyboard.End = 35
revkeyboard.Home = 36
revkeyboard.Left = 37
revkeyboard.Up = 38
revkeyboard.Right = 39
revkeyboard.Down = 40
revkeyboard.Select = 41
revkeyboard.Print = 42
revkeyboard.Execute = 43
revkeyboard.PrintScreen = 44
revkeyboard.Insert = 45
revkeyboard.Delete = 46
revkeyboard.Help = 47
revkeyboard.D0 = 48
revkeyboard.D1 = 49
revkeyboard.D2 = 50
revkeyboard.D3 = 51
revkeyboard.D4 = 52
revkeyboard.D5 = 53
revkeyboard.D6 = 54
revkeyboard.D7 = 55
revkeyboard.D8 = 56
revkeyboard.D9 = 57
revkeyboard.A = 65
revkeyboard.B = 66
revkeyboard.C = 67
revkeyboard.D = 68
revkeyboard.E = 69
revkeyboard.F = 70
revkeyboard.G = 71
revkeyboard.H = 72
revkeyboard.I = 73
revkeyboard.J = 74
revkeyboard.K = 75
revkeyboard.L = 76
revkeyboard.M = 77
revkeyboard.N = 78
revkeyboard.O = 79
revkeyboard.P = 80
revkeyboard.Q = 81
revkeyboard.R = 82
revkeyboard.S = 83
revkeyboard.T = 84
revkeyboard.U = 85
revkeyboard.V = 86
revkeyboard.W = 87
revkeyboard.X = 88
revkeyboard.Y = 89
revkeyboard.Z = 90
revkeyboard.LWin = 91
revkeyboard.RWin = 92
revkeyboard.Apps = 93
revkeyboard.Sleep = 95
revkeyboard.NumPad0 = 96
revkeyboard.NumPad1 = 97
revkeyboard.NumPad2 = 98
revkeyboard.NumPad3 = 99
revkeyboard.NumPad4 = 100
revkeyboard.NumPad5 = 101
revkeyboard.NumPad6 = 102
revkeyboard.NumPad7 = 103
revkeyboard.NumPad8 = 104
revkeyboard.NumPad9 = 105
revkeyboard.Multiply = 106
revkeyboard.Add = 107
revkeyboard.Separator = 108
revkeyboard.Subtract = 109
revkeyboard.Decimal = 110
revkeyboard.Divide = 111
revkeyboard.F1 = 112
revkeyboard.F2 = 113
revkeyboard.F3 = 114
revkeyboard.F4 = 115
revkeyboard.F5 = 116
revkeyboard.F6 = 117
revkeyboard.F7 = 118
revkeyboard.F8 = 119
revkeyboard.F9 = 120
revkeyboard.F10 = 121
revkeyboard.F11 = 122
revkeyboard.F12 = 123
revkeyboard.F13 = 124
revkeyboard.F14 = 125
revkeyboard.F15 = 126
revkeyboard.F16 = 127
revkeyboard.F17 = 128
revkeyboard.F18 = 129
revkeyboard.F19 = 130
revkeyboard.F20 = 131
revkeyboard.F21 = 132
revkeyboard.F22 = 133
revkeyboard.F23 = 134
revkeyboard.F24 = 135
revkeyboard.NumLock = 144
revkeyboard.Scroll = 145
revkeyboard.LShiftKey = 160
revkeyboard.RShiftKey = 161
revkeyboard.LControlKey = 162
revkeyboard.RControlKey = 163
revkeyboard.LMenu = 164
revkeyboard.RMenu = 165
revkeyboard.BrowserBack = 166
revkeyboard.BrowserForward = 167
revkeyboard.BrowserRefresh = 168
revkeyboard.BrowserStop = 169
revkeyboard.BrowserSearch = 170
revkeyboard.BrowserFavorites = 171
revkeyboard.BrowserHome = 172
revkeyboard.VolumeMute = 173
revkeyboard.VolumeDown = 174
revkeyboard.VolumeUp = 175
revkeyboard.MediaNextTrack = 176
revkeyboard.MediaPreviousTrack = 177
revkeyboard.MediaStop = 178
revkeyboard.MediaPlayPause = 179
revkeyboard.LaunchMail = 180
revkeyboard.SelectMedia = 181
revkeyboard.LaunchApplication1 = 182
revkeyboard.LaunchApplication2 = 183
revkeyboard.Oem1 = 186
revkeyboard.Oemplus = 187
revkeyboard.Oemcomma = 188
revkeyboard.OemMinus = 189
revkeyboard.OemPeriod = 190
revkeyboard.OemQuestion = 191
revkeyboard.Oemtilde = 192
revkeyboard.OemOpenBrackets = 219
revkeyboard.Oem5 = 220
revkeyboard.Oem6 = 221
revkeyboard.Oem7 = 222
revkeyboard.Oem8 = 223
revkeyboard.OemBackslash = 226
revkeyboard.ProcessKey = 229
revkeyboard.Packet = 231
revkeyboard.Attn = 246
revkeyboard.Crsel = 247
revkeyboard.Exsel = 248
revkeyboard.EraseEof = 249
revkeyboard.Play = 250
revkeyboard.Zoom = 251
revkeyboard.NoName = 252
revkeyboard.Pa1 = 253
revkeyboard.OemClear = 254
revkeyboard.KeyCode = 65535
revkeyboard.Shift = 65536
revkeyboard.Control = 131072
revkeyboard.Alt = 262144
revkeyboard.Modifiers = -65536

-- Keyboard
Keys.type["Keyboard"] = {}
for k, v in pairs(revkeyboard) do
  Keys.type["Keyboard"][v] = k
end

-- Switch Controller
Keys.type["Nintendo Switch Pro Controller"] = {
  [0] = "B",
  [1] = "A",
  [2] = "X",
  [3] = "Y",
  [4] = "L",
  [5] = "R",
  [6] = "-",
  [7] = "+",
  [8] = "SL",
  [9] = "SR",
  [10] = "ZL",
  [11] = "ZR",
  [12] = "Home"
}



return Keys
