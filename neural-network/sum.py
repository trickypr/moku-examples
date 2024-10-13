# Simple example to demonstrate the behaviour of a single neuron

# Intended as an educational exercise, this script trains a neural
# network to generate the weighted sum of the input channels with an optional
# bias/offset term. The model can then saved to disk for use with the Moku
# Neural Network instrument.

# %%
import os

import h5py
import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import dblquad

from moku.nn import LinnModel, save_linn

# %%
# ---
# Step 1: Generate input (3 channels) and output (one channel) data for training
# ---
nPts    = 1024
nCycles = 5
x       = np.linspace(0, nCycles * 2 * np.pi, nPts)

in1 = np.sin(x)

in2 = np.sign(in1)

in3 = 1/np.pi * ((x % (2*np.pi)) - np.pi)

offset = 0.1
amp1   = 0.1
amp2   = 0.2
amp3   = 0.3

out = amp1*in1 + amp2*in2 + amp3*in3 + offset

plt.figure()
plt.plot(in1)
plt.plot(in2)
plt.plot(in3)
plt.title('Inputs')

plt.figure()
plt.plot(out)
plt.title('Desired output')


# %%
# ---
# Step 2: Train a neural network to predict the output from the given inputs
# ---

# Reshape the inputs, ready for training. Each `data point' is three inputs and one output
inputs = np.vstack((in1, in2, in3)).transpose() # Shape is now nPts x 3
out.shape = [nPts, 1] # Shape is now nPts x 1

# Build the neural network model. Skip the I/O scaling as the data are already pretty good for training,
# Note that if you add scaling here, you'll need to apply the same scaling in the Moku Neural Network instrument at
# runtime.
linn_model = LinnModel()
linn_model.set_training_data(inputs, out, scale=False)

model_definition = [ (1, 'linear')] # A linear model should give a perfect prediction in this contrived case
                                    # Try some of the others below

# model_definition = [ (4, 'relu'), (4, 'relu')] # ReLU activation not great on signal reconstruction
# model_definition = [ (4, 'tanh'), (4, 'tanh')] # tanh has a range of +-1 which is more "voltage-like"
# model_definition = [ (16, 'tanh'), (16, 'tanh')] # A few more degrees of freedom to play around with
# model_definition = [ (100, 'tanh'), (100, 'tanh'), (100, 'tanh'), (100, 'tanh'), (100, 'tanh')] # Biggest Moku can fit, can overfit!

linn_model.construct_model(model_definition)

# %%
# Train the model. This simple model converges pretty quickly so an early stopping config terminates training much more quickly
history = linn_model.fit_model(epochs=500, validation_split=0.1, es_config={'patience': 10})

# plot the losses
plt.figure()
plt.semilogy(history.history['loss'])
plt.semilogy(history.history['val_loss'])
plt.legend(['loss', 'val_loss'])
plt.xlabel('Epochs')
plt.title('Loss functions')


# %%
# Plot the error between the actual and predicted points
nn_out = linn_model.predict(inputs)
fig, axs = plt.subplots(2)
fig.suptitle('Predicted output')
axs[0].plot(out,label='Desired')
axs[0].plot(nn_out,'--',label='Model output')
axs[0].legend()
axs[1].plot(nn_out-out,label='Model - Desired')
axs[1].legend()
plt.show()

# #%%
# #---
# #Step 3: Save the model to disk for use in the Moku Neural Network instrument
# #---

# Print model. It's educational to example the weights and biases visually and compare
# to the tuning knobs that were used to generate the data above.
ii = 0
for layer in linn_model.model.layers:
    if layer.get_weights():
        print(f'{ii}: ', 'Weights',layer.get_weights()[0].flatten().tolist(), ', Biases',layer.get_weights()[1].flatten().tolist())
        ii = ii + 1

save_linn(linn_model, input_channels=3, output_channels=1, file_name='sum.linn')


# File will look something like this
# {"version": "0.1",
#  "num_input_channels": 3,
#  "num_output_channels": 1,
#  "layers": [{"activation": "linear",
#              "weights": [[0.10000009834766388, 0.19999979436397552, 0.29999974370002747]],
#              "biases": [0.10000000149011612]}]}

# Output is approximately equal to 0.1*in1 + 0.2*in2 + 0.3*in3 + 0.1 as expected

# %%
