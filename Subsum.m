% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)

function x = Subsum(x, h, w)

[H,W,L] = size(x);

if H < h || W < w || mod(H,h) ~= 0 || mod(W,w) ~= 0 || h < 1 || w < 1 || ndims(x) > 3
    error('size error!')
end

if h ~= 1
    x = reshape(x,h,H/h*W,L);
    x = sum(x);
    x = reshape(x,H/h,W,L);
end
if w ~= 1
    x = permute(x,[2,1,3]); % transpose
    x = reshape(x,w,H/h*W/w,L);
    x = sum(x);
    x = reshape(x,W/w,H/h,L);
    x = permute(x,[2,1,3]); % transpose
end