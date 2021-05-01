function bits = ReadBits(path, frameNum, MBLK_H, MBLK_W)
filename = sprintf('%s%d.txt', path, frameNum);
in = load(filename);
bits = reshape(in, MBLK_W, MBLK_H)';
