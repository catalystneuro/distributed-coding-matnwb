# distributed-coding-matnwb
Converting the “Distributed coding” dataset ([Distributed coding of choice, action and engagement across the mouse brain](https://figshare.com/articles/dataset/Distributed_coding_of_choice_action_and_engagement_across_the_mouse_brain/9974357)) to NWB format using MatNWB conversion capabilities.

 * Convert Neuropixel electrophysiology data. Aim to build a function that can be applied generally to Neuropixel datasets that have a similar form.
 * Develop custom experiment-specific conversion code for behavioral data such as wheel position and lick times, and visual stimulation times.

INCF/Mathworks for Neuroscience summer project.

Resources:
* Data relating to [this paper](https://www.nature.com/articles/s41586-019-1787-x)
* This has been done in pynwb in [this repo](https://github.com/SteinmetzLab/dataToNWB)
* Analysis code [here](https://github.com/nsteinme/steinmetz-et-al-2019)
* NWB dandi-set [here](https://dandiarchive.org/dandiset/000017/draft)
* [MatNWB](https://github.com/NeurodataWithoutBorders/matnwb)
    * [writing extracellular electrophysiology data using MatNWB](https://www.youtube.com/watch?v=W8t4_quIl1k&ab_channel=NeurodataWithoutBorders)
    * [MatNWB advanced write](https://www.youtube.com/watch?v=PIE_F4iVv98&ab_channel=NeurodataWithoutBorders)
