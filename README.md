## 构建py-faster-rcnn

### 一、简介

py-faster-rcnn是基于caffe写的，原repo已经是很多年前的了，网上找的镜像都是四五年前的镜像，不能兼容现在的新CUDA和新GPU，要重新根据软硬件来构建。文档分为两个不同的版本，分别为太长不看版和炼狱踩坑版，任君选择阅读。

### 二、太长不看版

1. 克隆本项目

```
git clone http://10.168.1.155:2080/cv/py-faster-rcnn-ubuntu1804-cuda10.1.git
```

2. 导入镜像或者从头构建镜像

导入镜像：
```
docker load -i py-faster-rcnn.tar
```

从头构建镜像：
```
docker build -f Dockerfile -t py-faster-rcnn:caffe-ubuntu1804-cuda10.1 .
```

3. 启动镜像

```
docker run --gpus device=0 -it --rm -v /path/to/your/py-faster-rcnn/:/py-faster-rcnn py-faster-rcnn:caffe-ubuntu1804-cuda10.1 bash
```

4. 测试demo

```
cd /py-faster-rcnn
./tools/demo.py
```

### 三、炼狱踩坑版

如果你要从头来做一次，按照以下步骤：

1. 克隆py-faster-rcnn，然后在py-faster-rcnn里面克隆原版caffe和protobuf，稍后会用到。

```
git clone --recursive https://github.com/rbgirshick/py-faster-rcnn.git
cd py-faster-rcnn/
git clone https://github.com/BVLC/caffe.git
git clone https://github.com/google/protobuf.git
```

2. 启动容器，我们用的是```nvcr.io/nvidia/caffe:19.10-py2```这个镜像，请提前下载。

```
docker run --gpus device=0 -it --rm -v /path/to/your/py-faster-rcnn/:/py-faster-rcnn nvcr.io/nvidia/caffe:19.10-py2 bash
```

3. 重新编译protoc。

镜像内部的protoc版本较旧（3.6.0），编译py-faster-rcnn时会报protoc版本太旧的错误，因此要升级到3.9.0。以下命令均在容器内执行：

```
apt-get remove libprotobuf-dev protobuf-compiler
cd protobuf/
git checkout v3.9.0 # 我们用3.9.0版本
git submodule update --init --recursive
./autogen.sh
./configure
make
make check
make install
ldconfig
```

删除镜像内原有的protoc（3.6.0），换成新的protoc：

```
rm /usr/bin/protoc
cp /usr/local/bin/protoc /usr/bin/protoc
protoc --version # 你会看到：libprotoc 3.9.0
```

执行```pkg-config --libs protobuf```，你会得到：``` -L/usr/local/lib -lprotobuf```，把这句复制到```caffe-fast-rcnn/Makefile```的```LINKFLAGS```后面，400行：

```
LINKFLAGS += -pthread -fPIC $(COMMON_FLAGS) $(WARNINGS) -L/usr/local/lib -lprotobuf
```

参考链接：[https://gkwang.net/caffe_ssd/](https://gkwang.net/caffe_ssd/) 的第4点。

4. 复制caffe里面的一些文件到caffe-fast-rcnn内

因为caffe-fast-rcnn的代码比较旧，为了支持新版的cudnn，需要把最新的caffe源码中的一些代码替换到相应的目录中：

```
cd /py-faster-rcnn/caffe/include/caffe/util
cp cudnn.hpp /py-faster-rcnn/caffe-fast-rcnn/include/caffe/util
cd /py-faster-rcnn/caffe/include/caffe/layers/
cp cudnn_relu_layer.hpp cudnn_sigmoid_layer.hpp cudnn_tanh_layer.hpp /py-faster-rcnn/caffe-fast-rcnn/include/caffe/layers/
cd /py-faster-rcnn/caffe/src/caffe/layers/
cp cudnn_relu_layer.cpp cudnn_relu_layer.cu cudnn_sigmoid_layer.cpp cudnn_sigmoid_layer.cu cudnn_tanh_layer.cpp cudnn_tanh_layer.cu /py-faster-rcnn/caffe-fast-rcnn/src/caffe/layers/
```

然后修改```vim caffe-fast-rcnn/src/caffe/layers/cudnn_conv_layer.cu```，把```cudnnConvolutionBackwardFilter_v3```改成```cudnnConvolutionBackwardFilter```，把```cudnnConvolutionBackwardData_v3```改成```cudnnConvolutionBackwardData```。

5. 修改Makefile.config

请直接复制本项目里面的```caffe-fast-rcnn/Makefile.config```，不要作任何改动。你可以自行对比与```Makefile.config.example```的区别。

6. 开始构建

```
cd /py-faster-rcnn/caffe-fast-rcnn/
make -j20
make pycaffe -j20
export PYTHONPATH=/py-faster-rcnn/caffe-fast-rcnn/python/caffe/python:$PYTHONPATH
```

7. 装一些Python包

```
cd /py-faster-rcnn/caffe-fast-rcnn/python
for req in $(cat requirements.txt); do pip install $req -i https://pypi.tuna.tsinghua.edu.cn/simple; done
```

8. 测试demo

```
cd /py-faster-rcnn
./tools/demo.py
```
