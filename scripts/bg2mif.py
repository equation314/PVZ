from PIL import Image

MIF_WIDTH = 9
MIF_DEPTH = 33600
ZOOM = 5
RADIO = 1
file_list = ["background.jpg"]
outfile = "background.mif"

def compress(im):
	for i in xrange(0, im.size[0]):
		for j in xrange(im.size[1]):
			c = im.getpixel((i, j))
			c2 = map(lambda x: int(x / 32), c)
			c3 = tuple(map(lambda x: int(x * (255 / 7.0)), c2))
			# print i, j, c, c2, map(lambda x: x * 32, c2)
			im.putpixel((i, j), c3)
	return im

def write_mif(im, mif, t):
	for i in xrange(0, im.size[0]):
		for j in xrange(im.size[1]):
			c = im.getpixel((i, j))
			c2 = map(lambda x: x / 32, c)
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

	for file in file_list:
		im = Image.open(file)
		# im.resize((16, 16), Image.ANTIALIAS).save('2333.png');
		print (im.size[0] / ZOOM * RADIO, im.size[1] / ZOOM * RADIO)
		im = compress(im.resize(map(lambda x: int(x / ZOOM * RADIO), im.size), Image.ANTIALIAS))
		im.save(file[:-4] + "_small_compressed.png")
		print im.size

		miflines = write_mif(im, mif, miflines)

	print miflines
	mif.write("END;\n");
	mif.close()
