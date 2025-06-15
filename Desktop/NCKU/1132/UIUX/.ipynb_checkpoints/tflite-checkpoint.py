import tensorflow as tf
import tensorflow_hub as hub

# 1️⃣ 載入預訓練模型，並正確整合到 Keras 模型
inputs = tf.keras.Input(shape=(246000,), dtype=tf.float32)

# 創建一個自定義層來包裝 hub 模型
class Wav2Vec2Layer(tf.keras.layers.Layer):
    def __init__(self):
        super(Wav2Vec2Layer, self).__init__()
        self.wav2vec2 = hub.KerasLayer("https://tfhub.dev/vasudevgupta7/wav2vec2/1", 
                                        trainable=False)
    
    def call(self, inputs):
        return self.wav2vec2(inputs)

# 使用自定義層
wav2vec_layer = Wav2Vec2Layer()
outputs = wav2vec_layer(inputs)
model = tf.keras.Model(inputs, outputs)

# 2️⃣ 轉成 TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open("wav2vec2.tflite", "wb") as f:
    f.write(tflite_model)
    
print("Saved to wav2vec2.tflite")