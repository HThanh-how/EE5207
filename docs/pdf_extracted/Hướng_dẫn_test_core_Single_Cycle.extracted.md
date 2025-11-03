# Part 4 — Hướng dẫn test core Single Cycle (Original PDF)
**Source file:** Hướng dẫn test core Single Cycle.pdf


---

## Page 1

![Page 1 snapshot](/mnt/data/export_fitz_noocr/Hướng_dẫn_test_core_Single_Cycle/page-1.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(173.9, 35.9, 438.6, 58.0)`

```
Hướng dẫn test core Single 

```

**Block 2**  
`bbox=(252.2, 69.7, 360.2, 91.7)`

```
Cycle Vy Luong  

```

**Block 3**  
`bbox=(70.9, 112.3, 97.2, 123.3)`

```
Note  

```

**Block 4**  
`bbox=(76.2, 134.8, 544.1, 144.6)`

```
Mục đích của tài liệu hướng dẫn này là giúp sinh viên hiểu cách chạy các bài test và sử dụng testbench mẫu do 

```

**Block 5**  
`bbox=(58.9, 148.6, 130.9, 158.4)`

```
nhóm cung cấp.  

```

**Block 6**  
`bbox=(58.9, 163.5, 541.9, 173.3)`

```
Các bạn hoàn toàn có thể tự viết và thiết lập testbench riêng miễn là CPU RTL của bạn có thể chạy và vượt qua các 

```

**Block 7**  
`bbox=(58.9, 177.1, 254.2, 186.9)`

```
bài kiểm thử được quy định trong tài liệu này.  

```

**Block 8**  
`bbox=(46.9, 214.9, 234.8, 234.5)`

```
1. Cấu trúc testbench  

```

**Block 9**  
`bbox=(62.7, 246.4, 220.8, 256.1)`

```
Tệp dùng để test gồm 4 thư mục chính:  

```

**Block 10**  
`bbox=(60.4, 268.8, 317.7, 278.6)`

```
00_src: chứa toàn bộ mã nguồn RTL (source code) của các bạn.  

```

**Block 11**  
`bbox=(60.4, 286.4, 226.9, 296.2)`

```
01_bench: chứa tất cả các file testbench.  

```

**Block 12**  
`bbox=(60.4, 303.8, 410.7, 313.6)`

```
02_test: chứa các chương trình test (test program) dùng để kiểm tra hoạt động của DUT.  

```

**Block 13**  
`bbox=(60.4, 321.1, 321.3, 330.9)`

```
03_sim: chứa file makefile và các file phục vụ cho việc mô phỏng.  

```

**Block 14**  
`bbox=(62.7, 343.8, 493.2, 353.6)`

```
Trong cấu trúc testbench cơ bản, có 3 thành phần chính là driver, DUT (Design Under Test) và scoreboard.  

```

**Block 15**  
`bbox=(60.4, 366.3, 552.3, 376.1)`

```
Driver chịu trách nhiệm tạo và gửi các tín hiệu đầu vào đến DUT, đồng thời gửi thông tin tương tự đến scoreboard để làm dữ 

```

**Block 16**  
`bbox=(60.4, 379.6, 118.8, 389.4)`

```
liệu đối chiếu.  

```

**Block 17**  
`bbox=(60.4, 398.2, 534.5, 420.9)`

```
DUT là module mà bạn muốn test. Trong quá trình hoạt động, DUT sẽ tạo ra các tín hiệu đầu ra, những tín hiệu này được 
chuyển đến scoreboard để so sánh với kết quả mong đợi.  

```

**Block 18**  
`bbox=(60.4, 429.2, 551.7, 438.9)`

```
Scoreboard sẽ kiểm tra kết quả DUT trả về xem có đúng với giá trị kỳ vọng không. Nếu DUT vượt qua tất cả các bài test, quá 

```

**Block 19**  
`bbox=(59.7, 442.6, 215.8, 452.4)`

```
trình kiểm thử được xem là thành công. 

```

**Block 20**  
`bbox=(63.4, 466.1, 430.1, 475.9)`

```
Kết quả của từng bài test sẽ được hiển thị trực tiếp trên Terminal sau khi mô phỏng hoàn tất.  

```

**Block 21**  
`bbox=(45.4, 476.8, 254.8, 496.4)`

```
2. Cách chạy simulation  

```

**Block 22**  
`bbox=(70.9, 514.7, 548.1, 536.4)`

```
Testbench được nhắc đến trong hướng dẫn này đã được cung cấp sẵn trong thư mục home của bạn trên Server. 
Bạn chỉ cần copy thư mục này về workspace của mình, sau đó có thể bắt đầu test và chạy mô phỏng thiết kế RTL  

```

**Block 23**  
`bbox=(62.7, 555.6, 544.2, 565.4)`

```
Để thiết lập và chạy mô phỏng, bạn chỉ cần đặt tất cả file code RTL của mình (các file có phần mở rộng .sv hoặc .v ) vào thư 

```

**Block 24**  
`bbox=(46.2, 570.1, 445.2, 579.9)`

```
mục 00_src, sau đó vào thư mục 03_sim và chạy lệnh mô phỏng được định nghĩa trong file Makefile.  

```

**Block 25**  
`bbox=(70.9, 598.3, 321.9, 609.3)`

```
Lưu ý: Các bạn không cần chỉnh sửa bất kỳ file testbench nào.  

```

**Block 26**  
`bbox=(76.2, 620.4, 534.5, 630.2)`

```
Toàn bộ testbench đã được chuẩn bị sẵn, chỉ cần đảm bảo rằng bạn tuân thủ đúng hướng dẫn trong milestone 2, bao 

```

**Block 27**  
`bbox=(58.9, 634.6, 368.0, 644.4)`

```
gồm khai báo đầy đủ các tín hiệu đầu vào, đầu ra và tên tín hiệu theo yêu cầu.  

```

**Block 28**  
`bbox=(63.4, 672.8, 551.9, 682.5)`

```
Ban đầu, thư mục 03_sim chỉ chứa file makefile . Bước đầu tiên bạn cần làm là tạo một file có tên flist (filelist), trong đó liệt kê 

```

**Block 29**  
`bbox=(46.2, 687.1, 547.7, 696.9)`

```
tất cả đường dẫn đến các file code RTL và testbench. Trình mô phỏng sẽ dựa vào danh sách này để tìm và biên dịch code RTL.  

```

**Block 30**  
`bbox=(62.7, 709.9, 496.9, 719.7)`

```
Trong makefile , đã có sẵn một lệnh giúp bạn tạo filelist một cách tự động. Chỉ cần chạy lệnh sau trong terminal:  

```


---

## Page 2

![Page 2 snapshot](/mnt/data/export_fitz_noocr/Hướng_dẫn_test_core_Single_Cycle/page-2.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(63.4, 149.3, 556.5, 159.1)`

```
Lệnh này sẽ tự động tìm tất cả các file .sv , .v và .svh trong hai thư mục 00_src và 01_bench, sau đó ghi đường dẫn của chúng 

```

**Block 2**  
`bbox=(45.4, 163.6, 517.3, 173.4)`

```
vào file flist. Sau khi chạy xong, bạn có thể dùng lệnh ls để kiểm tra xem filelist ( flist ) đã được tạo thành công hay chưa.  

```

**Block 3**  
`bbox=(70.9, 312.3, 108.4, 322.1)`

```
Ghi chú:  

```

**Block 4**  
`bbox=(76.9, 333.2, 550.2, 343.0)`

```
Lệnh make create_filelist giúp gom tất cả các file RTL vào filelist. Tuy nhiên, bạn nên sắp xếp lại thứ tự trong filelist sao 

```

**Block 5**  
`bbox=(58.9, 347.3, 550.3, 357.1)`

```
cho phản ánh đúng hiearchy (thứ bậc) module trong thiết kế, tức là các module top level nên nằm ở cuối danh sách, còn 

```

**Block 6**  
`bbox=(58.9, 361.6, 172.7, 371.4)`

```
các module con ở phía trên.  

```

**Block 7**  
`bbox=(58.9, 377.0, 529.7, 386.8)`

```
Trình mô phỏng sẽ đọc file từ trên xuống, vì vậy nếu sắp xếp sai thứ tự, có thể trình mô phỏng sẽ không tìm thấy module 

```

**Block 8**  
`bbox=(58.9, 390.8, 197.1, 400.6)`

```
quan trọng trước khi cần biên dịch. 

```

**Block 9**  
`bbox=(63.4, 429.3, 328.7, 439.0)`

```
Sau khi đã có filelist, bạn có thể bắt đầu chạy mô phỏng bằng lệnh:  

```

**Block 10**  
`bbox=(63.4, 524.1, 545.9, 533.9)`

```
Bài test này dùng để kiểm tra chức năng cơ bản của từng lệnh trong tập lệnh RV32I. Khi chạy mô phỏng, scoreboard trong 

```

**Block 11**  
`bbox=(45.4, 537.8, 354.8, 547.6)`

```
testbench sẽ hiển thị trạng thái của bài test trên terminal, như hình bên dưới:  

```

**Block 12**  
`bbox=(63.4, 551.3, 541.4, 561.1)`

```
Phần hiển thị trong dấu ngoặc vuông [ ] ở bên trái thể hiện thời gian simulation mà mỗi bài test hoàn thành. Thông tin 

```

**Block 13**  
`bbox=(46.2, 565.6, 380.8, 575.4)`

```
này giúp bạn xác định vị trí lỗi trên waveform trong trường hợp bài kiểm thử thất bại.  

```

**Block 14**  
`bbox=(70.9, 593.8, 100.0, 604.8)`

```
Lưu ý:  

```

**Block 15**  
`bbox=(76.9, 615.2, 548.5, 625.0)`

```
Nếu bạn chạy mô phỏng mà không thấy trạng thái của bài test xuất hiện, hoặc kết quả bị gián đoạn trong thời gian 

```

**Block 16**  
`bbox=(58.9, 629.3, 548.3, 639.1)`

```
dài, điều đó có nghĩa là CPU Single Cycle của bạn đang gặp lỗi ở lệnh nhánh (Branch instruction) và có thể khiến lõi bị treo 

```

**Block 17**  
`bbox=(58.9, 643.6, 92.5, 653.4)`

```
vô hạn.  

```

**Block 18**  
`bbox=(76.0, 667.2, 537.0, 677.0)`

```
Trong trường hợp này, bạn cần kiểm tra lại cách xử lý lệnh nhánh trong thiết kế của mình trước khi chạy lại bài test. 

```

**Block 19**  
`bbox=(63.4, 704.4, 543.6, 714.1)`

```
Nếu trình mô phỏng xuất hiện lỗi hoặc cảnh báo, hãy kiểm tra lại mã RTL của bạn. Khi mô phỏng hoàn tất, bạn có thể quan 

```

**Block 20**  
`bbox=(45.4, 718.6, 542.0, 728.4)`

```
sát dạng sóng (waveform) để kiểm tra hoạt động của thiết kế bằng một trong hai lệnh sau để mở SimVision waveform viewer, 

```

**Block 21**  
`bbox=(45.4, 732.8, 323.3, 742.6)`

```
giúp bạn dễ dàng quan sát, debug và xác minh hoạt động của thiết kế:  

```


---

## Page 3

![Page 3 snapshot](/mnt/data/export_fitz_noocr/Hướng_dẫn_test_core_Single_Cycle/page-3.png)

### Text Blocks (ordered by coordinates)

**Block 1**  
`bbox=(63.4, 109.1, 210.6, 118.9)`

```
hoặc dùng simvision + tên file wave :  

```

**Block 2**  
`bbox=(46.2, 119.8, 214.6, 139.4)`

```
3. Cách chấm điểm  

```

**Block 3**  
`bbox=(62.7, 151.1, 547.5, 160.9)`

```
Để được chấm điểm, bạn cần nộp mã RTL và báo cáo trong một file .zip trước hạn nộp (sẽ được thông báo sau). Trợ giảng 

```

**Block 4**  
`bbox=(45.4, 165.1, 540.6, 174.9)`

```
sẽ nhận code RTL của bạn, tiến hành chấm điểm tự động (autograding) bằng cách chạy các bài test giống như hướng dẫn này 

```

**Block 5**  
`bbox=(45.4, 179.3, 218.7, 189.1)`

```
nhằm xác minh lại kết quả thiết kế của bạn.  

```

**Block 6**  
`bbox=(46.2, 194.0, 537.6, 203.8)`

```
Ngoài ra, còn có phần báo cáo và vấn đáp, trong đó giảng viên hoặc trợ giảng sẽ xem xét kết quả mô phỏng và đặt câu hỏi để 

```

**Block 7**  
`bbox=(45.4, 207.8, 285.9, 217.6)`

```
đánh giá mức độ hiểu biết và mức độ hoàn thiện của thiết kế. 

```

