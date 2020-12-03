FROM nvcr.io/nvidia/caffe:19.10-py2

ADD . /py-faster-rcnn

RUN cd /py-faster-rcnn/protobuf/ && \
  ./autogen.sh && \
  ./configure && \
  make -j8 && \
  make check -j8 && \
  make install -j8 && \
  ldconfig && \
  rm /usr/bin/protoc && \
  cp /usr/local/bin/protoc /usr/bin/protoc

RUN cd /py-faster-rcnn/caffe-fast-rcnn/ && \
  make -j8 && \
  make pycaffe -j8 && \
  export PYTHONPATH=/py-faster-rcnn/caffe-fast-rcnn/python/caffe/python:$PYTHONPATH

RUN cd /py-faster-rcnn/caffe-fast-rcnn/python && \
  for req in $(cat requirements.txt); do pip install $req -i https://pypi.tuna.tsinghua.edu.cn/simple; done

WORKDIR /py-faster-rcnn