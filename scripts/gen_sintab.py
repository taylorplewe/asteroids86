import math

with open("src/data/sintab.inc", "w") as f:
    f.write(".data\n\nsintab:\ndd ")
    for i in range(65):
        rad = (i / 64) * (math.pi/2)
        f.write(f"{(math.ceil(math.sin(rad) * 0x7fffffff)):08x}h")
        if (i+1) & 0x7 == 0:
            f.write("\ndd ")
        else:
            if i < 64:
                f.write(", ")
