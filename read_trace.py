import struct

def readfile(name):
    lines = [line.split(":", 1) for line in open(name, "r")]
    return {int(x[0], 16):x[1].rstrip() for x in lines}

filename = readfile("filename.txt")
function = readfile("function.txt")

with open("output.csv", "w") as output:
    with open("trace", "rb") as f:
        data = f.read(5 * 8)
        while data:
            raw = struct.unpack("QQQQQ", data)
            info = [filename[raw[0]], function[raw[1]], str(raw[2]), str(raw[3]), str(raw[4])]
            output.write(",".join(info))
            output.write("\n")
            data = f.read(5 * 8)


