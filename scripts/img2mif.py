from PIL import Image
import os

ANIM_FRAMES = 8
MIF_WIDTH = 12
MIF_DEPTH = 49152
SIZE = 32
anim_list = ["peashooter", "wallnut", "sunflower"]
zombie_list = ["zombie"]
# static_list = ["SeedBank"]
outfile = "objects.mif"

# plants:  0 00 000 0000000000 - 0 10 111 1111111111
# zombie:  1 0 0000 0000000000 - 1 0 1111 1111000000

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

	# widget
	'''
	for static in static_list:
		im = Image.open("statics/" + static + ".png")
		print static, miflines

		im = compress(im.resize((200, 70), Image.ANTIALIAS))
		im.save("statics/%s_small_compressed.png" % static)

		miflines = write_mif(im, mif, miflines)

	mif.write("\t[%d..%d]: 000000000000;\n" % (miflines, 0b100000000000000 - 1))
	miflines = 0b100000000000000
	'''

	# plants
	for anim in anim_list:
		if (not os.path.exists('anims/' + anim + '/small_compressed')):
			os.makedirs('anims/' + anim + '/small_compressed')
		for i in xrange(0, ANIM_FRAMES):
			im = Image.open("anims/%s/%d.png" % (anim, i))
			size = max(im.size[0], im.size[1])
			im2 = Image.new("RGBA", (size, size))
			print anim, i, miflines

			if (im.size[0] == size):
				offset = (size - im.size[1]) / 2
				im2.paste(im, (0, offset, im.size[0], im.size[1] + offset))
			else:
				offset =(size - im.size[0]) / 2
				im2.paste(im, (offset, 0, im.size[0] + offset, im.size[1]))

			im = compress(im2.resize((SIZE, SIZE), Image.ANTIALIAS))
			im.save("anims/%s/small_compressed/%d.png" % (anim, i))

			miflines = write_mif(im, mif, miflines)

	mif.write("\t[%d..%d]: 000000000000;\n" % (miflines, (1 << 15) - 1))
	miflines = (1 << 15)

	# zombie
	for anim in zombie_list:
		if (not os.path.exists('anims/' + anim + '/small_compressed')):
			os.makedirs('anims/' + anim + '/small_compressed')
		for i in xrange(0, 16):
			im = Image.open("anims/%s/%d.png" % (anim, i))
			im = im.convert("RGBA")
			size = max(im.size[0], im.size[1])
			im2 = Image.new("RGBA", (size, size))
			print anim, i, miflines

			if (im.size[0] == size):
				offset = (size - im.size[1]) / 2
				im2.paste(im, (0, offset, im.size[0], im.size[1] + offset))
			else:
				offset =(size - im.size[0]) / 2
				im2.paste(im, (offset, 0, im.size[0] + offset, im.size[1]))

			im = compress(im.resize((24, 40), Image.ANTIALIAS))
			im.save("anims/%s/small_compressed/%d.png" % (anim, i))

			miflines = write_mif(im, mif, miflines)

			n = (1 << 15) + ((i+1) << 10)
			mif.write("\t[%d..%d]: 000000000000;\n" % (miflines, n - 1))
			print i, miflines, n,
			miflines = n

#`mif.write("\t[%d..%d]: 000000000000;\n" % (miflines, 0b1000000000000000 - 1))
#	--miflines = 0b1000000000000000

	print miflines
	mif.write("END;\n");
	mif.close()
