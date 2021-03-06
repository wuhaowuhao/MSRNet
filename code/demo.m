% Attention
% This code has been tested successfully on GPU GTX-1080 with 12g memory
% If your GPU does not have enough memory and the code causes an "out of meory" error, 
% your can change the input_dim from 512 to 320 in the protoFile, but it will
% lead to accuracy loss of the predictions

% matcaffe path
matcaffePath = '../deeplab-caffe/matlab/';
addpath(matcaffePath)

% change to your images
data_root='../data';
img_id='00000';
suffix='.jpg';

% set parameters for the CNN model
models_root='../models_prototxts/';
model_id='VGG';

% GPU / CPU
useGPU = true;

isSave = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
param.protoFile = fullfile(models_root, sprintf('MSRNet-%s-test.prototxt',model_id));
param.modelFile = fullfile(models_root, sprintf('MSRNet-%s.caffemodel',model_id));

% init net
caffe.reset_all();
if exist(param.modelFile, 'file') == 0
  fprintf('%s does not exist.', param.modelFile);
end
if ~exist(param.protoFile,'file')
  error('%s does not exist.', param.protoFile);
end
if useGPU
  fprintf('Using GPU Mode\n');
  caffe.set_mode_gpu();
  caffe.set_device(0);
else
  fprintf('Using CPU Mode\n');
  caffe.set_mode_cpu;
end

net = caffe.Net(param.protoFile, param.modelFile, 'test');

im_data=imread(fullfile(data_root,'imgs',[img_id suffix]));
src=im_data;

data_shape=net.blobs('data').shape;
MAX_LEN=data_shape(1);

input=zeros(MAX_LEN, MAX_LEN, 3);

if max(max(size(im_data))) > MAX_LEN
  ratio = MAX_LEN / max(max(size(im_data))) ;
  im_data=imresize(im_data, ratio);
end

[H, W, ~]=size(im_data);
im_data = im_data(:, :, [3, 2, 1]);           % convert from RGB to BGR
im_data = permute(im_data, [2, 1, 3]);  % permute width and height
im_data = single(im_data);                    % convert to single precision

mean_pix = [104.008, 116.669, 122.675]; 
for c = 1:3, im_data(:,:,c,:) = im_data(:,:,c,:) - mean_pix(c); end
input(1:W,1:H,:)=im_data;

net.forward({input});
output = net.blobs('final_fusion').get_data();

smap=output(:,:,2);
smap=permute(smap,[2,1,3]);
smap=smap(1:H, 1:W);

%% show result
h=figure(1);    

subplot(1,2,1);
imshow(src);
title('Image');

subplot(1,2,2);
imshow(smap);
title('SaliencyMap'); 

%% save saliency map
if isSave
  save_dir = fullfile(data_root, 'pre');
  if ~exist(save_dir,'dir')
     mkdir(save_dir);
  end
  path=fullfile(save_dir,[img_id '.png']);
  imwrite(smap, path);
end
