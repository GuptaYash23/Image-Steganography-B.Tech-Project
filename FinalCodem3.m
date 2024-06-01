clc;
clear;
% cover_image=imread('lena_gray.bmp');   %COVER IMAGE
cover_image=imread('Boat.tiff');
%Resizing the cover image to size 512 x 512
cover_image=imresize(cover_image,[128 128]);

% Displaying the cover image
figure(1)
imshow(cover_image);
title('Cover Image');

% Reading the secret image that is to be hidden
hidden_image=imread('male.bmp');
% Resizing the cover image depending upon current_pixel_row pixel group and B bpp
hidden_image=imresize(hidden_image,[45 45]);
pattern=[1 0 2];

% Displaying the secret image
figure(2);
imshow(hidden_image);
title('Secret Image');

% Converting the secret image pixel matrix into 1D vector of pixels
row_vector_image = reshape(hidden_image,1,[]);
Data = row_vector_image;
% HI_height stores the height and HI_width stores the widht of the secret image
[HI_height,HI_width]=size(hidden_image);

% Perform Huffman Encoding
header=0;

% Computing Header for Huffman Encoding
POS=0; 
S_=size(Data);        
for i=1:S_(2)
    if (POS~=0)
      huffman_code_rows=size(header); F=0;
      huffman_code_cols=1;
      while (F==0 && huffman_code_cols<=huffman_code_rows(2))
         if (Data(i)==header(huffman_code_cols))  
             F=1; 
         end
         huffman_code_cols=huffman_code_cols+1;
      end
    else
        F=0;
    end
    if (F==0)
      POS=POS+1;
      header(POS)=Data(i);
    end
end

% Computing probaility of pixel values
S_H=size(header);
Count(1:S_H(2))=0;
for i=1:S_H(2)
    for j=1:S_(2)
        if (Data(j)==header(i))
            Count(i)=Count(i)+1;
        end
    end
end
Count=Count./S_(2);

% Sorting the pixel values according to their occurrences decreasingly
for i=1:S_H(2)-1
    for j=i+1:S_H(2)
        if (Count(j)>Count(i))
            T1=Count(i); Count(i)=Count(j); Count(j)=T1;
            T1=header(i); header(i)=header(j); header(j)=T1;
        end
    end
end

 % Creating Huffman dictionary using 
 % header variable that stores the unique pixel values
 % Count variable that stores the probability of occurrence corresponding
 % to header variable
[dictionary,average_length_of_bit] = huffmandict(header,Count);
% Encoding the data. huffman_code stores the encoded data
huffman_code = huffmanenco(Data,dictionary); 
 % Stores the size of the huffman encoded data
len1 = size(huffman_code,2);   
bin_num_message = huffman_code(:); 
% Stores the parameter of the huffman encoded data [ huffman_code_height=1, huffman_code_width=len1]
[huffman_code_height,huffman_code_width]=size(huffman_code);    

% Stores number of bits used to represent Hidden Image
bits_required=HI_height*HI_width*8;
% Stores the number of bits saved using Huffman encoding
saved_bits=bits_required-len1;
% Stores the percentage improvement after Huffman encoding
percentage_improvement=(saved_bits/bits_required)*100;

% Now embedding the encoded code using Lag_Transform

% headerlength is used to store the size of the sec
headerlength=32;    
% CI_height & CI_width contains rows and cols of cover image   
[CI_height,CI_width]=size(cover_image);   
[huffman_code_rows,huffman_code_cols]=size(hidden_image);    % huffman_code_rows & huffman_code_cols contains rows and cols of huffman coded data

% Contains total no. of bits of secret image (huffman code)
bits_to_be_embedded_length=huffman_code_height*huffman_code_width;  

% Bits to store the height of the hidden image huffman code      
bits_to_store_HI_height=uint8(headerlength/2);   

% Bits to store the width of the hidden image huffman code
bits_to_store_HI_width=uint8(headerlength-bits_to_store_HI_height);  % bits_to_store_HI_width = 16

% char array stores huffman code rows in binary form [1x16]
bits_HI_height=dec2bin(huffman_code_rows,bits_to_store_HI_height);   

% converts [1x16] char array to [16x1] char array
bits_HI_height=reshape(bits_HI_height',[],1); 

% char array stores huffman code cols in binary form [1x16]
bits_HI_width=dec2bin(huffman_code_cols,bits_to_store_HI_width);      

% converts [1x16] char array to [16x1] char array
bits_HI_width=reshape(bits_HI_width',[],1); 

% 32X1 arrays containing 0s so that it can store size of image
sizebits=uint8(zeros(headerlength,1));   

for j=1:uint8(headerlength)
    if(j<=bits_to_store_HI_height)
        sizebits(j)=uint8(bits_HI_height(j)-48);  % converting char into numbers
    else
        sizebits(j)=uint8(bits_HI_width(j-bits_to_store_HI_width)-48);   % converting char into numbers
    end 
end

actualbits=huffman_code; 

% Converts non char array from size row vector representation to col
% vector representation
actualbits=reshape(actualbits',[],1);

% Stores the total no. of bits to be embedded
totalnoofbitstobeembedded=bits_to_be_embedded_length+headerlength;  


for i=1:totalnoofbitstobeembedded
    if(i<=headerlength)
        % First 32 bits store CI_height, CI_width size in binary
        watermarkbits(i)=uint8(sizebits(i)); 
    else
        % Remaining bits store binary representation of secret image as int
        watermarkbits(i)=uint8(actualbits(i-headerlength)); 
    end
end

% Stores the rows of the pixel group
pixel_group_rows=1;
% Stores the cols of the pixel group
pixel_group_cols=3;   

% Finds the total no. of rows required
rows_covered = ceil(CI_height / pixel_group_rows);
% Finds the total no. of cols required
cols_covered = ceil(CI_width / pixel_group_cols);  

% Finding the rows required for embedding procedure for perfect division
if rem(CI_height,pixel_group_rows)==0
    % To find the eff. row size
    rows_required=rem(CI_height,pixel_group_rows);  
else
     % To modify the value to the eff. row size
    rows_required=pixel_group_rows-rem(CI_height,pixel_group_rows);
end

% Finding the cols required for embedding procedure for perfect division
if rem(CI_width,pixel_group_cols)==0
    % To find the eff. col size
    cols_required=rem(CI_width,pixel_group_cols);
else
    % To modify the value to the eff. col size
    cols_required=pixel_group_cols-rem(CI_width,pixel_group_cols);
end

% Reshapes the image for perfect division into the pixel group
cover_image = padarray(cover_image, [rows_required cols_required], 'replicate','pre');

% CI_height,CI_width now stores the update row and col size of the cover image
[CI_height,CI_width]=size(cover_image);

% Creates the same matrix as that of cover image initialized with 0s
bin=zeros(CI_height,CI_width,'uint8');

% Checks whether embedding process is completed or not
embedding_completed=0;
traversed_bits=1;
traversed_bits=uint32(traversed_bits);
%Embed_pattern= [1 0 2] / [2 0 3] / [3 2 4] / [4 3 5]
Embed_pattern=pattern;
count=0;


% Embedding process

for i=1:rows_covered                    % 1 2 3 .... rows_covered
    for j=1:cols_covered                % 1 2 3 .... cols_covered
        
        % Gets the non-intersecting blocks of the CI for embedding
        single_block=cover_image(((i-1)*pixel_group_rows)+1,(j-1)*pixel_group_cols+(1:pixel_group_cols));
        
        % Applying Laguerre Transform on the selected block
        transformed_block=uint32(Lag_Transform(uint32(single_block))); 
        backup_transformed_block=transformed_block; 
        
        for current_pixel_row=1:pixel_group_rows    % 1
            for current_pixel_col=1:pixel_group_cols  % 1 2 
                individual_pixel=transformed_block(current_pixel_row,current_pixel_col);  % Gets each element from 1x3 block
                   
                for bpp_value_bits=1:Embed_pattern(current_pixel_row*current_pixel_col)  % 1 2   [1 1] / [2 2] / [3 3] / [4 4]
                    if(traversed_bits<=totalnoofbitstobeembedded) 
                        % If bit to be encoded is 1
                        if watermarkbits(traversed_bits)==1 
                            individual_pixel=bitor(individual_pixel,(2^(bpp_value_bits-1)));
                        % If bit to be encoded is 0
                        else                               
                             individual_pixel=bitand(individual_pixel,bitcmp((2^(bpp_value_bits-1)),'uint16'));
                        end
                        %transformed_block(current_pixel_row,current_pixel_col)=individual_pixel;
                        traversed_bits=traversed_bits+1;
                       
                    else
                        embedding_completed=1;
                        break;
                    end
                     
                    if(embedding_completed)
                        break;
                    end
                end
                if(embedding_completed)
                    break;
                end
                 
                transformed_block(current_pixel_row,current_pixel_col)=individual_pixel;  % stores the embedded bits
                
            end
             
        end
       
          % Post embedding pixel adjustment in case distortion is high 
        
         transformed_block(1,1)=pixel_adjustment(backup_transformed_block(1,1),transformed_block(1,1),Embed_pattern(1));
         transformed_block(1,2)=pixel_adjustment(backup_transformed_block(1,2),transformed_block(1,2),Embed_pattern(2));
         transformed_block(1,3)=pixel_adjustment(backup_transformed_block(1,3),transformed_block(1,3),Embed_pattern(3));
         
          % Inverse Laguerre Transform is used to get back the pixel block 1x3
         
         In_one_block=uint32(Inv_Lag_Transform(int32(transformed_block)));

        for current_pixel_row=1:pixel_group_rows  %1
            for current_pixel_col=1:pixel_group_cols  % 1 2 3
                pixelval=In_one_block(current_pixel_row,current_pixel_col);
                bin((i-1)*pixel_group_rows+current_pixel_row,(j-1)*pixel_group_cols+current_pixel_col)=pixelval;
            end
        end
    end
end

% Dislays and Saves the Stego Image
figure(3);
imshow(bin);
title('Stego Image');
imwrite(bin,'Stego.tiff'),

% Stores PSNR, MSE and SSIM metrics of the Stego Image
PSNR=psnr(cover_image,bin);
MSE=immse(cover_image,bin);
ssimval=ssim(cover_image,bin);


% Extraction process

% Reads the Stego Image
stego_image=imread('Stego.tiff');
[SI_height,SI_width]=size(stego_image);   

% To get the size of the hidden image
extraction_headerlength=32;
extraction_message_height=0;
extraction_message_height=uint32(extraction_message_height);
extraction_message_width=0;
extraction_message_width=uint32(extraction_message_width);

% Number of bits that stores the height and width of the secret image
extraction_msg_width_length=uint8(extraction_headerlength/2);            
extraction_msg_height_length=uint8(extraction_headerlength-extraction_msg_width_length);  

% Set the extract pattern which will be similar to embed patttern
Extract_pattern=Embed_pattern;
extraction_pixel_group_rows=pixel_group_rows;
extraction_pixel_group_cols=3;
extraction_block_rows = ceil(SI_height / extraction_pixel_group_rows);  
extraction_block_cols = ceil(SI_width / extraction_pixel_group_cols);  

mask=0;
Exflag=0;
bits_retrieved=1;
bits_retrieved=uint32(bits_retrieved);

Exbin=zeros(SI_height,SI_width,'uint32');  
newpixel=0;


% Iterates through all blocks and cols
for i=1:extraction_block_rows      
    for j=1:extraction_block_cols  
        
        % Gets the non-intersecting blocks of the SI for extraction
        ex_one_block=stego_image((i-1)*extraction_pixel_group_rows+[1:extraction_pixel_group_rows],(j-1)*extraction_pixel_group_cols+[1:extraction_pixel_group_cols]);
        
        % Applying Laguerre Transform on the selected block
        ex_tn_one_block=uint32(Lag_Transform(uint32(ex_one_block)));
        
        for current_pixel_row=1:extraction_pixel_group_rows    
            for current_pixel_col=1:extraction_pixel_group_cols   
                extracted_pixel=ex_tn_one_block(current_pixel_row,current_pixel_col);          % Selects each element from 1x3 block
                for ex_bpp_value_bits=1:Extract_pattern(current_pixel_row*current_pixel_col)       % 1 2 3 [3 2 4]
                    newpixel=newpixel+1;
                    if bits_retrieved<=extraction_msg_width_length     
                        if ((bitand(extracted_pixel,(2^(ex_bpp_value_bits-1))))~=0)
                            extraction_message_height=extraction_message_height+2^(uint32(extraction_msg_width_length)-uint32(bits_retrieved));
                        end
                    elseif((bits_retrieved>extraction_msg_width_length)&&(bits_retrieved<=extraction_headerlength))   % <=32
                        if ((bitand(extracted_pixel,(2^(ex_bpp_value_bits-1))))~=0)
                            extraction_message_width=extraction_message_width+2^(uint32(extraction_headerlength)-uint32(bits_retrieved));
                        end
                    else   
                        
                        if ((bitand(extracted_pixel,(2^(ex_bpp_value_bits-1))))~=0)
                            extracted_bits(bits_retrieved-extraction_headerlength)=1;
                        else
                            extracted_bits(bits_retrieved-extraction_headerlength)=0;
                            
                        end
               

                       if(bits_retrieved==extraction_headerlength+huffman_code_width)
                            disp('Extract entered')
                     
                            
                            Exflag=1;
                            break;
                        end
                    end
                    
                    
                    if(Exflag)
                        break;
                    end
                    bits_retrieved=bits_retrieved+1;
                end
                if(Exflag)
                    break;
                end
            end
            if(Exflag)
                break;
            end
        end
        if(Exflag)
            break;
        end
    end
    if(Exflag)
        break;
    end
end

% Decode recovered_pixels from the bit array using Huffman decoding
recovered_pixels = huffmandeco(extracted_bits, dictionary); 
% Converting the recovered_pixels to int8 (0-255) format from double (0-1)
recovered_pixels=uint8(recovered_pixels);

% Calculate the required size
required_size = extraction_message_height * extraction_message_width;

% Adjust the size of recovered_pixels to match the required size
if numel(recovered_pixels) < required_size
    % Pad with zeros if there are fewer elements
    recovered_pixels(end+1:required_size) = 0;
elseif numel(recovered_pixels) > required_size
    % Trim excess elements if there are more elements
    recovered_pixels = recovered_pixels(1:required_size);
end

% Reshape recovered_pixels to the desired dimensions
secret_image = reshape(recovered_pixels, [extraction_message_height, extraction_message_width]);

% If necessary, reshape secret_image to the final desired dimensions
secret_image = reshape(secret_image, [HI_height, HI_width]);
secret_image = reshape(recovered_pixels,[extraction_message_height,extraction_message_width]);
secret_image=reshape(recovered_pixels,[HI_height,HI_width]);
figure(4);
imshow(secret_image);
title('Retrieved Image');

disp('Percentage improvement in the embedding capacity is');
disp(percentage_improvement);
disp('PSNR of the stego image is');
disp(PSNR);
disp('SSIM of the stego image is');
disp(ssimval);
