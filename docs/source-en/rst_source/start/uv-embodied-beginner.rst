UV Beginner Setup (Non-Docker, Embodied)
=========================================

This guide is for RL beginners who want to:

1. Set up RLinf with ``uv`` (no Docker).
2. Start a multi-node Ray cluster.
3. Run a minimal embodied training job without large VLA model weights first.


When to use this path
---------------------

* You are new to RLinf.
* You want to understand config structure and distributed flow before OpenVLA/OpenPI.
* You have a multi-node GPU cluster.


Step 1: Install minimal dependencies with UV (env-only)
--------------------------------------------------------

Run on every node from the RLinf repository root:

.. code-block:: bash

   pip install --upgrade uv
   bash requirements/install.sh embodied --env maniskill_libero --venv .venv-embodied
   source .venv-embodied/bin/activate

Notes:

* This installs embodied + ``maniskill_libero`` environment dependencies only.
* It intentionally skips OpenVLA/OpenPI model-specific dependencies for a lighter first run.


Step 2: Start multi-node Ray (set RLINF_NODE_RANK first)
---------------------------------------------------------

On each node, set node rank **before** ``ray start``.

Head node example:

.. code-block:: bash

   export RLINF_NODE_RANK=0
   ray start --head --port=6379 --node-ip-address=<HEAD_IP>

Worker node example:

.. code-block:: bash

   export RLINF_NODE_RANK=1  # increment per node
   ray start --address=<HEAD_IP>:6379

Optional: if you use ``ray_utils/start_ray.sh``, ``RANK=<id>`` is still supported and will be mirrored to ``RLINF_NODE_RANK`` automatically.


Step 3: Learn the key config fields first
-----------------------------------------

Start from:

* ``examples/embodiment/config/maniskill_sac_mlp_multinode_quickstart.yaml``

Core fields:

.. code-block:: yaml

   cluster:
     num_nodes: 2
     component_placement:
       actor,env,rollout: all

What they mean:

* ``cluster.num_nodes``: total number of training nodes (must match reality).
* ``component_placement``: worker placement; ``all`` uses all visible GPUs for collocated components.
* ``env.train.total_num_envs`` / ``env.eval.total_num_envs``: environment parallelism.
* ``actor.micro_batch_size`` / ``actor.global_batch_size``: memory/throughput tradeoff.


Step 4: Run the minimal training job
------------------------------------

Launch only on the head node:

.. code-block:: bash

   bash examples/embodiment/run_embodiment.sh maniskill_sac_mlp_multinode_quickstart

If you prefer running ``python`` directly, ensure the repo root is on ``PYTHONPATH`` first, or install RLinf into this virtual environment:

.. code-block:: bash

   export PYTHONPATH=/data/RLinf:$PYTHONPATH
   python examples/embodiment/train_embodied_agent.py \
     --config-path examples/embodiment/config \
     --config-name maniskill_sac_mlp_multinode_quickstart

Or:

.. code-block:: bash

   uv pip install -e /data/RLinf


Step 5: Verify it is healthy
----------------------------

* ``ray status`` shows all nodes and GPUs.
* Training logs continue printing (for example ``train/`` metrics).
* A new experiment directory appears under ``results/`` or ``logs/``.


Next step: switch to VLA models
-------------------------------

After this minimal path works:

1. Install model-specific dependencies (for example ``--model openvla`` or ``--model openpi``).
2. Switch to a VLA config such as ``maniskill_ppo_openvla*_quickstart``.
3. Set model checkpoints in ``actor.model.model_path`` and ``rollout.model.model_path``.

See :doc:`installation` for full dependency options and :doc:`distribute` for more distributed examples.
