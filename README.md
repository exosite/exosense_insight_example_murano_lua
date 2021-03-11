# ExoSense™ Insight How-To Guide

## Basic Concepts

ExoSense™ Insight Modules are processes that act on Asset Signals within the
application. They allow customers to integrate in a flexible way with a wide
array of internal and external services to provide analytics, decision, and
action capabilities. Correspondingly, there are two types of Insights:

* Transforms
* Rules

### Streaming

Fundamentally, all Insights are streaming based. This is also more widely known as an 
[Online Algorithm](https://en.wikipedia.org/wiki/Online_algorithm).

* At their core, Insights are not stateful; similar to other
  Transformations like Join and Linear Gain, they operate on a single piece of
  Signal data.
* For a given function on multiple signals, such as: SignalA and SignalB, each time a piece of
  data comes in from _either_ of those Signals, the function runs (and returns a value).
* It is the function's responsibility to remember prior data from signals if that is
  important for it to run.
* This code by default retains prior values sent to an instance of a function automatically
  to simplify the author's job of focusing on the logic and less on interfacing.

## Creating a new Insight Module

### Create a new Application from Exchange

Goto the Exchange Template for this repo `url goes here`.

Click on the `Create Application` button.

### Edit the module `your_code_here`

Click on `Modules`, then on `your_code_here`.

Add your logic.

#### Publish Your Exchange Insight Element

* In Murano, go to IoT Marketplace and click on Publish on the left
* Parameters:
  * Element name: Recommend including 'Insight' in the name.
  * Element type: Service
  * Element Variation: ExoSense Insight
  * Configuration File (YAML) URL: https://`<`the domain of your application`>`/interface
  * ... (fill the rest out as you see fit)

#### Add Insight To Business

Go to the Element you created in IoT Marketplace and add it to your Murano Business.

#### Add Insight To ExoSense

Go to the ExoSense instance Solution in Murano, and click the orange "Enable
Services" button at the top right. Find the Service you just created and enable
it. Your Insight is now available to use in ExoSense!
