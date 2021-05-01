% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)

function x = Kron3d(x,y)

[H,W,L] = size(x);
x = reshape(x,H,W*L);
x = kron(x,y);
x = reshape(x,H*size(y,1),W*size(y,2),L);