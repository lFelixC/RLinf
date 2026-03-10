UV 新手上手（非 Docker，Embodied）
====================================

本教程面向 RL 新手，目标是：

1. 不使用 Docker，仅使用 ``uv`` 配置 RLinf 环境。
2. 在多机多 GPU 上启动 Ray 集群。
3. 先跑通一个不依赖大模型权重的最小具身训练配置（MLP + ManiSkill）。


适用场景
---------

* 你刚接触 RLinf。
* 你希望先理解配置结构和分布式流程，再切换到 OpenVLA/OpenPI。
* 你有多机多 GPU 环境。


步骤 1：用 UV 安装最小依赖（不装大模型）
--------------------------------------------

在每台机器上，进入 RLinf 根目录后执行：

.. code-block:: bash

   pip install --upgrade uv
   bash requirements/install.sh embodied --env maniskill_libero --venv .venv-embodied --install-rlinf
   source .venv-embodied/bin/activate

说明：

* 该命令只安装 ``embodied`` + ``maniskill_libero`` 环境依赖，不安装 OpenVLA/OpenPI 等模型依赖。
* 适合先跑 MLP 配置验证流程。


步骤 2：启动多机 Ray（先设置 RLINF_NODE_RANK）
---------------------------------------------------

请在每台机器上，**先设置**节点编号，再启动 Ray。``RLINF_NODE_RANK`` 必须在 ``ray start`` 之前设置。

Head 节点（示例）：

.. code-block:: bash

   export RLINF_NODE_RANK=0
   ray start --head --port=6379 --node-ip-address=<HEAD_IP>

Worker 节点（示例）：

.. code-block:: bash

   export RLINF_NODE_RANK=1  # 依次递增
   ray start --address=<HEAD_IP>:6379

可选：若你用仓库脚本 ``ray_utils/start_ray.sh``，可继续使用 ``RANK=<id>``，脚本会自动同步为 ``RLINF_NODE_RANK``。


步骤 3：先理解配置结构
-----------------------

建议先阅读并基于下面这个配置开始：

* ``examples/embodiment/config/maniskill_sac_mlp_multinode_quickstart.yaml``

其中最关键的字段如下：

.. code-block:: yaml

   cluster:
     num_nodes: 2
     component_placement:
       actor,env,rollout: all

含义：

* ``cluster.num_nodes``：参与训练的总节点数，必须与实际一致。
* ``component_placement``：组件放置策略；``all`` 表示使用集群中全部可见 GPU（共享式）。
* ``env.train.total_num_envs`` / ``env.eval.total_num_envs``：环境并行度。
* ``actor.micro_batch_size`` / ``actor.global_batch_size``：训练批大小与显存/吞吐平衡。


步骤 4：运行最小训练
----------------------

仅在 Head 节点启动训练：

.. code-block:: bash

   bash examples/embodiment/run_embodiment.sh maniskill_sac_mlp_multinode_quickstart

若你希望直接使用 ``python`` 命令，请先确保仓库根目录在 ``PYTHONPATH`` 中，或先把 RLinf 安装到当前虚拟环境：

.. code-block:: bash

   export PYTHONPATH=/data/RLinf:$PYTHONPATH
   python examples/embodiment/train_embodied_agent.py \
     --config-path examples/embodiment/config \
     --config-name maniskill_sac_mlp_multinode_quickstart

或：

.. code-block:: bash

   uv pip install -e /data/RLinf


步骤 5：验证是否跑通
----------------------

* ``ray status`` 能看到全部节点和 GPU 资源。
* 训练日志持续输出（例如 ``train/`` 指标）。
* ``results/`` 或 ``logs/`` 下生成新实验目录。


下一步：切换到 VLA 模型
-------------------------

当 MLP 流程跑通后，再切换到 OpenVLA/OpenPI：

1. 安装对应模型依赖（``--model openvla`` 或 ``--model openpi``）。
2. 将配置切换到 ``maniskill_ppo_openvla*_quickstart`` 或其它目标配置。
3. 补齐模型权重路径（``actor.model.model_path`` 与 ``rollout.model.model_path``）。

更多安装细节请参考 :doc:`installation`，多机策略请参考 :doc:`distribute`。
