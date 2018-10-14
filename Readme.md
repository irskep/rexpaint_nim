# REXPaint for Nim

```nim
import rexpaint

let image = newREXPaintImage("xptest.xp")

# "REXPaintImage(10x10, 2 layers)"
echo image 

# layer, x, y
let cell = image.get(0, 0, 0)
echo "code: ", cell.code
echo "foreground color: ", cell.fgColor
echo "background color: ", cell.bgColor
```