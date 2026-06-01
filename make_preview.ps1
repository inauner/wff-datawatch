# Compose a faithful MOCK preview (450x450) of the Data 9 face with sample data,
# using the exact positions + colors from res/raw/watchface.xml, so the rainbow
# color-by-position scheme is visible. This is a store/README preview only.
Add-Type -AssemblyName System.Drawing
$W = 450; $cx = 225; $cy = 225
$bmp = New-Object System.Drawing.Bitmap $W, $W
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear([System.Drawing.Color]::Black)

function HexBrush($hex) {
  $r=[Convert]::ToInt32($hex.Substring(0,2),16); $gg=[Convert]::ToInt32($hex.Substring(2,2),16); $b=[Convert]::ToInt32($hex.Substring(4,2),16)
  New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,$r,$gg,$b))
}
$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment='Center'; $sfC.LineAlignment='Center'
function Lbl($text,$x,$y,$size,$hex){
  $f = New-Object System.Drawing.Font('Segoe UI',$size); $br = HexBrush $hex
  $rect = New-Object System.Drawing.RectangleF($x,$y,110,($size*1.7))
  $g.DrawString($text,$f,$br,$rect,$sfC)
}
function LblB($text,$x,$y,$size,$hex){
  $f = New-Object System.Drawing.Font('Segoe UI Semibold',$size); $br = HexBrush $hex
  $rect = New-Object System.Drawing.RectangleF($x,$y,110,($size*1.7))
  $g.DrawString($text,$f,$br,$rect,$sfC)
}

# ---- rainbow rim ring (HSV by angle, 0=top, clockwise) ----
$penW = 9
for ($a=0; $a -lt 360; $a++) {
  $hue = $a
  # HSV->RGB at full sat/val
  $h=$hue/60.0; $i=[math]::Floor($h)%6; $ff=$h-[math]::Floor($h)
  $v=255; $p=0; $q=[int]($v*(1-$ff)); $t=[int]($v*$ff)
  switch($i){0{$r=$v;$gg=$t;$b=$p}1{$r=$q;$gg=$v;$b=$p}2{$r=$p;$gg=$v;$b=$t}3{$r=$p;$gg=$q;$b=$v}4{$r=$t;$gg=$p;$b=$v}5{$r=$v;$gg=$p;$b=$q}}
  $col=[System.Drawing.Color]::FromArgb(120,$r,$gg,$b)
  $pen=New-Object System.Drawing.Pen($col,$penW)
  # GDI arc: 0deg=3o'clock, CW positive. Our 0=top => gdi = a-90.
  $g.DrawArc($pen,($cx-213),($cy-213),426,426,($a-90),1.4)
  $pen.Dispose()
}

# ---- center time / date / moon / seconds ----
$fTime = New-Object System.Drawing.Font('Segoe UI',60)
$g.DrawString('10:08',$fTime,(HexBrush 'ffffff'),(New-Object System.Drawing.RectangleF(0,150,450,90)),$sfC)
$g.DrawString('36',(New-Object System.Drawing.Font('Segoe UI',22)),(HexBrush '9a9a9a'),(New-Object System.Drawing.RectangleF(0,232,450,34)),$sfC)
$g.DrawString('Sun 31',(New-Object System.Drawing.Font('Segoe UI',16)),(HexBrush 'd0d0d0'),(New-Object System.Drawing.RectangleF(125,134,200,28)),$sfC)
$g.DrawString('Waning Gibbous 15',(New-Object System.Drawing.Font('Segoe UI',9)),(HexBrush 'd0d0d0'),(New-Object System.Drawing.RectangleF(125,118,200,16)),$sfC)

# ---- built-ins: label (grey) + value (position color) ----
# BAT 12
Lbl 'BAT' 170 15 9 '808080';      LblB '86%' 170 29 16 '00ff00'
# STEPS 7
Lbl 'STEPS' 81 352 9 '808080';    LblB '8.4k' 81 366 16 'ff5500'
# LA 3
Lbl 'LA' 348 197 9 '808080';      LblB '17' 348 211 16 '0073ff'
# HR 6 (big red)
Lbl 'HR' 170 350 9 '808080';      LblB '72' 170 360 26 'ff0000'

# ---- complication labels + mock values (position color) ----
# SUN 11
Lbl 'SUN' 81 48 9 '808080';       LblB '5:49' 81 64 16 '55ff00'
# Itin 1
Lbl 'Itin' 259 42 9 '707070';     LblB '9a' 259 58 16 '00ff84'
# Timer 2
Lbl 'Timer' 325 108 9 '707070';   LblB '0:00' 325 124 16 '00f7ff'
# DIST 4
Lbl 'DIST' 325 288 9 '808080';    LblB '2.4' 325 302 16 '1100ff'
# FLOORS 5
Lbl 'FLOORS' 259 356 9 '808080';  LblB '12' 259 368 16 '9500ff'
# AZM 8
Lbl 'AZM' 15 286 9 '808080';      LblB '21' 15 302 16 'ffaa00'
# UV 9
Lbl 'UV' 0 197 9 '808080';        LblB '3' 0 213 16 'ffff00'
# TEMP 10
Lbl 'TEMP' 15 108 9 '808080';     LblB '58' 15 124 16 'aaff00'

$g.Dispose()
$out = Join-Path $PSScriptRoot 'res\drawable\preview.png'
$bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"preview written: $out"
