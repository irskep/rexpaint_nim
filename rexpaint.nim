import sequtils
import system
import zip/zlib

# REXPaintCell

type REXPaintCell* = ref object
  code*: int32
  fgColor*: (uint8, uint8, uint8)
  bgColor*: (uint8, uint8, uint8)
proc newREXPaintCell*(code: int32, fgColor: (uint8, uint8, uint8), bgColor: (uint8, uint8, uint8)): REXPaintCell =
  REXPaintCell(code: code, fgColor: fgColor, bgColor: bgColor)  

proc `$`*(image: REXPaintCell): string =
  return "REXPaintCell(" & $(image.code) & ")"

# REXPaintImage

proc find4Int32sInsideCharArray(arr: string, start: int = 0): ptr array[0..3, int32] =
  return cast[ptr array[0..3, int32]](unsafeAddr(arr[start]))

proc findInt32InsideCharArray(arr: string, pos: int): int32 =
  return cast[ptr array[0..0, int32]](unsafeAddr(arr[pos]))[0]

proc readColor(arr: string, start: int): (uint8, uint8, uint8) =
  let r = cast[uint8](arr[start])
  let g = cast[uint8](arr[start + 1])
  let b = cast[uint8](arr[start + 2])
  return (r, g, b)

type REXPaintImage* = ref object
  version*: int32
  width*: int32
  height*: int32
  layers: seq[seq[REXPaintCell]]
proc newREXPaintImage*(filename: string): REXPaintImage =
  # exercise .xp parse
  let compressedBytes = readFile(filename)
  let signedBytes = uncompress(compressedBytes, compressedBytes.len, GZIP_STREAM)

  let initialInt32s = find4Int32sInsideCharArray(signedBytes, 0)
  let version = initialInt32s[0]
  let layersCount = initialInt32s[1]
  let width = initialInt32s[2]
  let height = initialInt32s[3]
  let cellsPerLayer = width * height

  var layers = newSeqWith(layersCount, newSeq[REXPaintCell](cellsPerLayer))
  for i in 0..<layersCount:
    newSeq(layers[i], cellsPerLayer)

  let bytesInPreamble = 8 # version, layersCount, w, h
  let bytesPerCell = 10 # code(4) + rgb(3) + rgb(3)
  let bytesPerLayer = 4 + 4 + (bytesPerCell * cellsPerLayer)

  for layerIndex in 0..<layersCount:
    let layerByteStart = bytesInPreamble + layerIndex * bytesPerLayer
    let cellByteStart = layerByteStart + 8 # w, h
    for cellIndex in 0..<cellsPerLayer:
      let cellByteIndex = cellByteStart + bytesPerCell * cellIndex
      let code = findInt32InsideCharArray(signedBytes, cellByteIndex)
      layers[layerIndex][cellIndex] = newREXPaintCell(
        code, readColor(signedBytes, cellByteIndex + 4), readColor(signedBytes, cellByteIndex + 7))
  
  return REXPaintImage(version: version, width: width, height: height, layers: layers)

proc `$`*(image: REXPaintImage): string =
  return "REXPaintImage(" & $(image.width) & "x" & $(image.height) & ", " & $(image.layers.len) & " layers)"  

proc get*(image: REXPaintImage, layer: int, x: int, y: int): REXPaintCell =
  return image.layers[layer][x * int(image.height) + y]