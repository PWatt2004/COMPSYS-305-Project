import sys
from PIL import Image
# https://github.com/Nananas/ImageToMif


if (len(sys.argv) > 4):
    dims = int(sys.argv[1])
    input_filename = sys.argv[2]
    output_filename = sys.argv[3]
    temp = sys.argv[4]

    im = Image.open(input_filename)
    im = im.crop(im.getbbox())
    im = im.resize((dims, dims))  # Resize the image to required dimensions
    im.show()
    if im.mode != 'RGB':
        im = im.convert('RGB')
    f = open(output_filename, 'w');

    print("> Image size: ")
    print(im.size)
    print("")
    w = im.size[0]
    h = im.size[1]

    print("> Writing to file: "+ output_filename)
    index = int(temp)

    for y in range(0, h):
        for x in range(0, w):
            r = im.getpixel((x, y))[0] & 240
            g = im.getpixel((x, y))[1] & 240
            b = im.getpixel((x, y))[2] & 240

            total = (r << 4) | g | (b >> 4)

            binary = bin(total)[2:].zfill(12)  # Convert to binary format

            if total == 0:
                binary = "000000000000"  # Handle the special case when total is 0

            f.write(hex(index)[2:] + ":\t" + binary + ";\n")  # Write binary data

            index += 1

    f.write("END;")

    print(">>> DONE");

else:
    print("NEED MOAR INFO")
