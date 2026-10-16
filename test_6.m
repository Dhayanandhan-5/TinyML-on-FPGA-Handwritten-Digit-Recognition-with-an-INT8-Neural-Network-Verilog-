w_1 = reshape(w1', [], 1);

w_2 = reshape(w2', [], 1);

w_3 = reshape(w3', [], 1);

w_4 = reshape(w4', [], 1);

w = [w_1;w_2;w_3;w_4];

wx = dec2bin(w, 8);

b_1 = reshape(b1', [], 1);

b_2 = reshape(b2', [], 1);

b_3 = reshape(b3', [], 1);

b_4 = reshape(b4', [], 1);

b = [b_1;b_2;b_3;b_4];

bx = dec2bin(b, 8);

in=in';
inx = dec2bin(in, 8);
writematrix(wx, 'D:\fpga\prj\tinyML\weights.txt', 'Delimiter', ' ');
writematrix(bx, 'D:\fpga\prj\tinyML\baises.txt', 'Delimiter', ' ');
writematrix(inx, 'D:\fpga\prj\tinyML\picture.txt', 'Delimiter', ' ');
