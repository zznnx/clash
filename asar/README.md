asar文件解压打包

1.安装npm<br>
apt-get install npm 

2.安装asar<br>
npm install -g asar

使用方法: <br>
解压: <br>
asar extract [压缩文件] [解压文件夹]<br>
压缩: (如果压缩文件存在，则会被替换)<br>
asar pack [文件夹] [压缩文件名]