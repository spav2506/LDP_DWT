% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% read motion vectors from input file
% 
% Input
%     path: (string) containing directory and file name prefix
%     frameNum: (integer value) frame number
%     BLK_H: (integer value) number of horizontal blocks (height)
%     BLK_W: (integer value) number of vertical blocks (width)
%     PEL_MC: (integer value) indicating 1/n-pel motion compensation
%     
% Output
%     mv_x: (matrix) x-component of motion vecters 
%     mv_y: (matrix) y-component of motion vecters

function [mv_x, mv_y] = ReadMVs(path, frameNum, BLK_H, BLK_W, PEL_MC)

filename = sprintf('%s%d.txt', path, frameNum);
mvIn = load(filename);
mv_x = reshape(mvIn(2:2:end), BLK_W, BLK_H);
mv_y = reshape(mvIn(1:2:end), BLK_W, BLK_H);
mv_x = (mv_x'./PEL_MC);
mv_y = (mv_y'./PEL_MC);
