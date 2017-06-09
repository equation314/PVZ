from PIL import Image
import os

ANIM_FRAMES = 8
MIF_WIDTH = 12
MIF_DEPTH = 4608
SIZE = 32
peasun_list = ["sun", "pea", "pea_splat"]
size_list = [(64, 64), (16, 16), (16, 16)]
outfile = "peasun.mif"

# sun:       0 000000000000 -  0 111111111111
# pea:       1 000 0 00000000 - 1 000 0 11111111
# pea_splat: 1 000 1 00000000 - 1 000 1 11111111

def compress(im):
	for i in xrange(0, im.size[0]):
		for j in xrange(im.size[1]):
			c = im.getpixel((i, j))
			c2 = map(lambda x: int(x / 32), c)
			c3 = tuple(map(lambda x: int(x * (255/7.0)), c2))
			# print i, j, c, c2, map(lambda x: x * 32, c2)
			im.putpixel((i, j), c3)

	return im

def write_mif(im, mif, t):
	for i in xrange(0, im.size[0]):
		for j in xrange(0, im.size[1]):
			c = im.getpixel((i, j))
			c2 = map(lambda x: x >> 5, c)
			mif.write("\t%d: " % t)
			if (MIF_WIDTH == 9):
				c2 = c2[0: 3]
			for k in c2:
				mif.write("%03d" % int(bin(k)[2:]));
			mif.write(";\n")
			t += 1
	return t

if (__name__ == "__main__"):
	mif = open(outfile, "w")
	mif.write("WIDTH=%d;\n" % MIF_WIDTH);
	mif.write("DEPTH=%d;\n\n" % MIF_DEPTH);

	mif.write("ADDRESS_RADIX=UNS;\n");
	mif.write("DATA_RADIX=BIN;\n\n");

	mif.write("CONTENT BEGIN\n");
	miflines = 0

	for i in xrange(0, len(peasun_list)):
		file = peasun_list[i];
		im = Image.open("statics/" + file + ".png")
		print file, miflines

		im = compress(im.resize(size_list[i], Image.ANTIALIAS))
		im.save("statics/%s_small_compressed.png" % file)

		miflines = write_mif(im, mif, miflines)

	print miflines
	mif.write("END;\n");
	mif.close()
