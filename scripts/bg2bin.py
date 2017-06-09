import struct
from PIL import Image

MIF_WIDTH = 9
MIF_DEPTH = 33600
ZOOM = 1.25
RADIO = 1
file_list = ["background.jpg"]
outfile = "background.bin"

def compress(im):
	for i in xrange(0, im.size[0]):
		for j in xrange(im.size[1]):
			c = im.getpixel((i, j))
			c2 = map(lambda x: int(x / 32), c)
			c3 = tuple(map(lambda x: int(x * (255 / 7.0)), c2))
			# print i, j, c, c2, map(lambda x: x * 32, c2)
			im.putpixel((i, j), c3)
	return im

def write_bin(im, file):
	for i in xrange(0, im.size[0]):
		for j in xrange(im.size[1]):
			c = im.getpixel((i, j))
			c2 = map(lambda x: x / 32, c)
			num = (c2[0] << 6) + (c2[1] << 3) + c2[2]
			h = struct.pack("I", num)
			file.write(h)

def write_bin(im1, im2, im3, file):
	for i in xrange(0, im1.size[0]):
		for j in xrange(im1.size[1]):
			c1 = map(lambda x: x / 32, im1.getpixel((i, j)))
			c2 = map(lambda x: x / 32, im2.getpixel((i, j)))
			c3 = map(lambda x: x / 32, im3.getpixel((i, j)))
			num = (((((0 << 3) + c1[0]) << 3) + c1[1]) << 3) + c1[2];
			num = (((((num << 3) + c2[0]) << 3) + c2[1]) << 3) + c2[2];
			num = (((((num << 3) + c3[0]) << 3) + c3[1]) << 3) + c3[2];
			h = struct.pack("I", num)
			# print num, bin(num), c1, c2, c3
			file.write(h)

if (__name__ == "__main__"):
	output = open(outfile, "wb")

	im1 = Image.open("start.jpg")
	im2 = Image.open("lose.jpg")
	im3 = Image.open("background.jpg")

	im1 = compress(im1.resize((640, 480), Image.ANTIALIAS))
	im1.save("start_small_compressed.png")
	print im1.size

	im2 = compress(im2.resize((640, 480), Image.ANTIALIAS))
	im2.save("lose_small_compressed.png")
	print im2.size

	im3 = compress(im3.resize(map(lambda x: int(x / ZOOM * RADIO), im3.size), Image.ANTIALIAS).crop((200, 0, 840, 480)))
	im3.save("background_small_compressed.png")
	print im3.size

	write_bin(im1, im2, im3, output)

	output.close()
