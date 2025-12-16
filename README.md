# ScreamingBird
CPE 487 Final Project: Voice/Noise Controlled Flappy Bird

[Poster Link](https://github.com/pherrer/ScreamingBird/blob/main/images/cpe%20487%20flappy%20bird%20poster.pdf)


## Overview:
Our project is a sound controlled version of Flappy Bird. It will be based on Labs 3 (Bouncing Ball) and 6 (Pong) for reference. The game will display a shape (representing the "bird") you have to guide through a series of obstacles by making a noise. If a loud enough noise is detected by the system, it will move the “bird” up a set distance. We do not plan on adding specific voice recognition or keywords to make the “bird” move up. Rather, the noise just theoretically needs to reach a certain decibel level to be registered by the system and trigger the upward movement.

Please view the credits at the bottom!

## How to use: 
_Controls:_
Shout, clap, or make an otherwise loud-ish noise into the audio input! Each noise will move the bird up a fixed amount. Keep making noise to navigate the bird through the pipes! Each time you go through a pipe, you get a point. If the bird hits a pipe, you lose!

_How to Win:_
Don't crash the bird into a pipe, keep making noises so it stays up!!!! Check your score on the LED screen!

NOTE: DO LAB INSTRUCTIONS !!!!!!!


## Hardware Requirements:
- Nexys A7-100T FPGA Board
- Audio Input (built into the Nexys Board already!)
- External Monitor + VGA Connector

## Software:
- Vivado (using VHDL as the designated code for this project) 

## Files:
- flap_top.vhd: top module where components are called
- bird_and_pipes.vhd : game logic and on-screen functionality
- pdmdes.vhd: noise detection and thresholding using the board's onboard mic 
- clk_wiz_0.vhd : display to VGA monitor
- clk_wiz_0_clk_wiz.vhd : display to VGA monitor
- leddec16.vhd : use the FPGA board to display a score counter
- vga_sync.vhd : control the dimensions of the game on the display
- flap_top.xhd: constraints file containing port mapping to the board and files

## Expected Behavior
1. The system outputs the game display to a VGA monitor operating at a fixed resolution of 800×600 pixels. All game elements, including the bird, pipes, and background, are rendered within this display area.

2. The bird’s vertical position is updated every clock cycle based on a gravity model that applies a constant downward acceleration. In the absence of user input, the bird continuously descends toward the bottom of the screen.

3. Audio input from the PDM microphone is processed entirely in hardware to generate a digital loudness value. This value is continuously compared against a predefined threshold. When the loudness exceeds the threshold, a jump signal is asserted, causing an immediate upward velocity to be applied to the bird, resulting in a vertical jump.

4. Pipes are generated at fixed horizontal intervals and scroll from right to left across the screen at a constant speed. Each pipe pair contains a vertical gap that the bird must pass through. The horizontal and vertical positions of the bird and pipes are continuously monitored for overlap.

5. A collision event is detected if the bird intersects with any pipe or if its vertical position exceeds the upper or lower screen boundaries. Upon collision detection, the game enters a game-over state, halting bird motion and pipe scrolling.

6. The score increments by one each time the bird successfully passes a pipe pair without collision. The current score is output in real time on an external 7-segment display, which updates immediately upon each successful pass and operates independently of the VGA display.

### Diagram and System
[System function diagram](https://github.com/pherrer/ScreamingBird/blob/main/images/Flappy_bird_diagram.png)
[Physical Hardware System](https://github.com/pherrer/ScreamingBird/blob/main/images/System.jpeg)
[Physical Hardware System with Minitor](https://github.com/pherrer/ScreamingBird/blob/main/images/Hardware.jpeg)

### FSM:
At this finite state machine, we used 0 to represent successful data passing (not falling or not striking any objects), and 1 for error data (falling or hitting a pipe). 
- State 1 represents system initiation: before system begins running and program in reset
- State 2 represents system begins: system starts running and program is initiated
- State 3 represents system ongoing: game is in progress
- State 4 represents system failure: game is failed and final score is being printed on the monitor
- 
[Finite State Machine for Flappy Bird](https://github.com/pherrer/ScreamingBird/blob/main/images/Flappy%20Bird%20FSM.png)

### Inputs/Outputs:

### Modifications:

This project was mainly built by extending and integrating different aspects, structures, files, and other material from CPE 487 Labs as well as previous CPE 487 projects. The primary goal of this project was not to soley re-use these structures, but to expand upon them with new functionality. Using these references, we were able to re-design game logic into an independent and functioning audio-driven Flappy Bird game.

The main modifications and referencing from other labs are listed below:

- #### <ins>flap_top.vhd:</ins> modified from lab 6's [pong.vhd](https://github.com/byett/dsd/blob/CPE487-Fall2025/Nexys-A7/Lab-6/pong.vhd) and flappy atilla's [flappy.vhd](https://github.com/BriannaPGarland/FlappyAttila/blob/main/ProjectFiles/flappy.vhd)

The flap_top.vhd file serves as the top level integration point for our Screaming Bird project. The file was modified from Lab 6's pong.vhd, Flappy Atilla's flap_top.vhd, and components from the Audio Visual Equalizer project. The overall structure remains similar but the functionality was significantly expanded to include audio controlled gameplay as opposed to button or potentiometer based control.

In Flappy Atilla, the bird's movement is controlled using an ADC (potentiometer) input, which directly maps an analog voltage to the bird's position. In this project, the ADC functionalities were removed and replaced with a PDM mic interface using the PdmDes module. This module (sourced from karlsheng99's Audio Visual Equalizer project) converts the microphone's PDM bitstream into 16 bit sampled dara. This change alters the input mechanism of the game, controlling the bird using discrete jump events based on detected sound intensity as opposed to continuous position control.

A loudness detection algorithim was added to analyse the mic input by counting the no. of logic high bits ('1') in each PDM sample. When this count exceeded a modifiable threshold, the system generates a "loud" signal, which is then converted to a single frame pulse synced up to the VGA vertical sync. This makes it so that each sound produces one bird "flap" (vertical movement of a fixed size). As a result of this, the bird is controlled by noise, and multiple jumps from sustained sounds are prevented. The audio input is aligned with the game's frame based physics.

Another modification includes edge detection and frame synced flap control. We implemented this logic specifically to prevent continuous jumping when a loud sound is sustained. Instead of directly feeding the loudness into the game logic, loud_clk is sampled on the rising edge of the vga vertical sync (s_vsync) which occurs once per frame (60 Hz). By comparing current and previous loudness states, the system generates a single cycle flap_req pulse only when a rising edge (aka from quiet to loud) is derected. Thus, each loud sound produces only one jump.

In addition to this, this top module has new subsystems & additions to subsystems in order to implement our audio processing and game logic. We port map the mic ports to the constraints file in order to link the audio processing and general game logic together. The architecture also includes new mic signals as well as flap pulse. We instantiated the microphone noise detector process as well as a noise-to-jump process into the architecture as well. The structure and formatting of Flappy Atila's flappy.vhd and Lab 6's pong.vhd were referenced as well to ensure the code worked as intentioned. 

The VGA pipeline, clk_wiz_0 implemtations, and leddec files were unchanged. 

- #### <ins>bird_and_pipes.vhd:</ins> modified from lab 6's [bat_n_ball.vhd](https://github.com/byett/dsd/blob/CPE487-Fall2025/Nexys-A7/Lab-6/bat_n_ball.vhd) and flappy atilla's [bird_n_buildings.vhd](https://github.com/BriannaPGarland/FlappyAttila/blob/main/ProjectFiles/bird_n_buildings.vhd)

The original bat_n_ball and Flappy Atilla's bird_n_buildings served as the foundation and reference for our bird_and_pipes file. While these references provided a baseline for vga drawing and frame based game updates, we redesigned the logic to support audio controlled gameplay, simplified collision logic, and custom pipe & bird behavior. Instead of a horizontally moving bat and ball with full range of movement, this file now manages a vertically moving bird, produces pipes with random gaps and detects collisions. 

In Flappy Atilla, the bird and buildings are drawn using sprites and several draw processes (such as duckdraw, buildingdraw, gapdraw, and backgrounddraw). We wanted to move away from this approach in preference of a simpler, mathematics based approach. Our project replaced this sprite rendering with mathematical shape drawing, drawing the bird as a circle w/ the circle equation (refrenced from bat_n_ball) and draws the pipes as rectangular regions w/ a vertical gap.

The bird is drawn using distanced based bath, (vx * vx + vy * vy) < (bsize * bsize) , which implements the circle equation. This is especially convenient as the bird size can be easily adjusted. This approach was adapted from Lab 6's ball drawing logic.

The bird's motion system was also majorly modified to use velocity based physics as opposed to Flappy Atilla's position-only control. By implementing signals for the bird's y positon and vertical velocity, we are able to control the bird's movement with a flap input (making it jump up) and the effect of gravity (continuously increasing downwards velocity). We also set a maximum fall velocity to avoid unrealistic acceleration. Separating the signals for the bird's position and velocity also allowed for a cleaner integration of audio-triggered flaps.

Another major modification was the addition of an audio-driven control interface, requiring a noise to convert to a flap input to make the bird move up a fixed amount. The flap input is a single frame pulse that is generated from the mic input's loudness. The bird then jumps only on a rising edge audio event, preventing repeated flaps from a continuous noise. Continuing the point of rising edge basedlogic, all game updates occur on wait until rising_edge(v_sync); , which means that gameplay speed is independent of FPGA clock frequency. This approach was inspired by Lab 6, but further expanded to control all physics, scoring, collision, detection, and randomization.

We also modified pipe respawn and the pseudo-random gap generation. Flappy Atilla uses arithmetic expressions tied to score to reposition the gaps. However, in our project, the pipe gaps are randomized using a Linear Feedback Shift Register. This approach was chosen as it was simpler and faster than the orginal expressions, and ensured visually varied pipe / gap placements. In terms of gaps, pipes, and collisons, we used axis aligned bounding boxes to check for collisions. The bird is approximated as a square, and the pipes are considered rectangles w/ a vertical exclusion zone (gap). The collision checks are then separated into horiziontal and vertical overlaps.

- #### <ins>pdmdes.vhd:</ins> used karlsheng99's complete [pdmdes.vhd](https://github.com/karlsheng99/CPE487_DigitalSystemDesign/blob/master/project/AudioVisualEqualizer/AudioVisualEqualizer.srcs/sources_1/new/PdmDes.vhd)

The pdmdes.vhd file was sourced from karlsheng99's Audio Visual Equalizer project and used w/o modification. Full credit is given to him for the original implementation. 

This module handles the deserialization of the pdm microphone's high freq 1-bit data stream into stable 16 bit samples. PDM microphone interfacing requires precise clock generation and timing control, making it a significantly complex part of the project. Due to time constraints and several major bugs throughout other aspects of the project, a reliable and tested module was re-used and credited. This allowed us to focus on the higher level system design. In particular, we were able to focus and refine the conversion of this audio data and using the resulting signal to control gameplay behavior. 

While the pdmdes.vhd file itself was resused, its output was processed by our logic to create a single frame jump signal, synced up to the vga frame rate.


## Summary of Process:

Conclude with a summary of the process itself – who was responsible for what components (preferably also shown by each person contributing to the github repository!), the timeline of work completed, any difficulties encountered and how they were solved, etc. (10 points of the Submission category)

## Credits:
### past dsd projects:

- https://github.com/BriannaPGarland/FlappyAttila/tree/main
- https://sites.google.com/stevens.edu/cpe487website/project
- https://github.com/I-Gringeri/FinalProjectCPE487
- https://github.com/Arif12467/Digital-System-Design-AIA/tree/main/Final-Project
- https://github.com/karlsheng99/CPE487_DigitalSystemDesign/tree/master/project
- https://github.com/karlsheng99/CPE487_DigitalSystemDesign/blob/master/project/AudioVisualEqualizer/AudioVisualEqualizer.srcs/sources_1/new/PdmDes.vhd
- https://github.com/Arif12467/Digital-System-Design-AIA/blob/main/Final-Project/Test-6/PdmDes.vhd

### outside projects/references:

- https://www.secs.oakland.edu/~llamocca/Courses/ECE4710/W22/FinalProject/Group7_flappybird.pdf
- https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual?srsltid=AfmBOoouMjAwKUqbr0LgrgV_uC05SJKV512vV2uWS_w70B1NHi0PrJ6b 
- https://www.rtlaudiolab.com/006-fpga-audio-deserializer/
- https://blog.nanax.fr/post/2019-05-28-vhdl-blobbyfish/

### dsd labs:

- https://github.com/byett/dsd/tree/CPE487-Fall2025/Nexys-A7/Lab-3
- https://github.com/byett/dsd/tree/CPE487-Fall2025/Nexys-A7/Lab-5
- https://github.com/byett/dsd/tree/CPE487-Fall2025/Nexys-A7/Lab-6

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


### What to Submit:
Your final submission should be a github repository of very similar format to the labs themselves with an opening README document with the expected components as follows:

* A description of the expected behavior of the project, attachments needed (speaker module, VGA connector, etc.), related images/diagrams, etc. (10 points of the Submission category)
		* The more detailed the better – you all know how much I love a good finite state machine and Boolean logic, so those could be some good ideas if appropriate for your system. If not, some kind of high level block diagram showing how different parts of your program connect together and/or showing how what you have created might fit into a more complete system could be appropriate instead.
	* A summary of the steps to get the project to work in Vivado and on the Nexys board (5 points of the Submission category)
 	* Description of inputs from and outputs to the Nexys board from the Vivado project (10 points of the Submission category)
  		* As part of this category, if using starter code of some kind (discussed below), you should add at least one input and at least one output appropriate to your project to demonstrate your understanding of modifying the ports of your various architectures and components in VHDL as well as the separate .xdc constraints file.
	* Images and/or videos of the project in action interspersed throughout to provide context (10 points of the Submission category)
	* “Modifications” (15 points of the Submission category)
		* If building on an existing lab or expansive starter code of some kind, describe your “modifications” – the changes made to that starter code to improve the code, create entirely new functionalities, etc. Unless you were starting from one of the labs, please share any starter code used as well, including crediting the creator(s) of any code used. It is perfectly ok to start with a lab or other code you find as a baseline, but you will be judged on your contributions on top of that pre-existing code!
		* If you truly created your code/project from scratch, summarize that process here in place of the above.
	* Conclude with a summary of the process itself – who was responsible for what components (preferably also shown by each person contributing to the github repository!), the timeline of work completed, any difficulties encountered and how they were solved, etc. (10 points of the Submission category)
* And of course, the code itself separated into appropriate .vhd and .xdc files. (50 points of the Submission category; based on the code working, code complexity, quantity/quality of modifications, etc.)
* You are not really expected to be github experts – as long as one of you can confidently create the repository and help others add to it, that should be sufficient. If no group members fall under this criteria, discuss with me as soon as possible.
	* This is a group assignment, and for the most part you are graded as a group. I reserve the right to modify single student grades for extenuating circumstances, such as a clear lack of participation from a group member. You are allowed to rely on the expertise of your group members in certain aspects of the project, but you should all have at least a cursory understanding of all aspects of your project.
