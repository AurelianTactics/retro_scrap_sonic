"""
Environments and wrappers for Sonic training.
"""

import gym
import numpy as np

from baselines.common.atari_wrappers import WarpFrame, FrameStack
import gym_remote.client as grc
from retro_contest.local import make #added for local

def make_env(stack=True, scale_rew=True, scenario = 'trajectory_max'): #scenario =  #'contest'
    """
    Create an environment with some standard wrappers.
    """
    #env = grc.RemoteEnv('tmp/sock')
    #dqn
    #env = make(game='SonicTheHedgehog-Genesis', state='GreenHillZone.Act1', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='GreenHillZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='GreenHillZone.Act3', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='ScrapBrainZone.Act1', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='ScrapBrainZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='SpringYardZone.Act1', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='SpringYardZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='SpringYardZone.Act3', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='StarLightZone.Act1', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='StarLightZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='StarLightZone.Act3', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='LabyrinthZone.Act1', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='LabyrinthZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='MarbleZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='MarbleZone.Act1', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='MarbleZone.Act3', bk2dir='videos', monitordir='logs')
    #ppo
    #env = make(game='SonicTheHedgehog-Genesis', state='GreenHillZone.Act2', bk2dir='videos', monitordir='logs')

    #solving levels/loaded dqn
    #env = make(game='SonicTheHedgehog-Genesis', state='GreenHillZone.Act2', bk2dir='videos', monitordir='logs')
    #env = make(game='SonicTheHedgehog-Genesis', state='MarbleZone.Act1', bk2dir='videos', monitordir='logs', scenario=scenario)
    #env = make(game='SonicTheHedgehog-Genesis', state='MarbleZone.Act2', bk2dir='videos', monitordir='logs',scenario=scenario)
    #env = make(game='SonicTheHedgehog-Genesis', state='SpringYardZone.Act1', bk2dir='videos', monitordir='logs',scenario=scenario)
    env = make(game='SonicTheHedgehog-Genesis', state='LabyrinthZone.Act1', bk2dir='videos', monitordir='logs',scenario=scenario)

    env = SonicDiscretizer(env)
    if scale_rew:
        env = RewardScaler(env)
    env = WarpFrame(env)
    if stack:
        env = FrameStack(env, 4)
    return env

class SonicDiscretizer(gym.ActionWrapper):
    """
    Wrap a gym-retro environment and make it use discrete
    actions for the Sonic game.
    """
    def __init__(self, env):
        super(SonicDiscretizer, self).__init__(env)
        buttons = ["B", "A", "MODE", "START", "UP", "DOWN", "LEFT", "RIGHT", "C", "Y", "X", "Z"]
        # actions = [['LEFT'], ['RIGHT'], ['LEFT', 'DOWN'], ['RIGHT', 'DOWN'], ['DOWN'],
        #            ['DOWN', 'B'], ['B']]
        #actions = [['LEFT'], ['RIGHT'], ['LEFT', 'B'], ['RIGHT', 'B'],  ['NOOP'],['B']]
        #actions = [['LEFT'], ['RIGHT'], ['LEFT', 'DOWN'], ['RIGHT', 'DOWN'], ['RIGHT', 'B'], ['DOWN'], ['NOOP'], ['B']]
        #actions = [['LEFT'], ['RIGHT'], ['NOOP'], ['B']]
        actions = [['LEFT'], ['RIGHT'], ['DOWN'], ['NOOP'], ['B']]
        self._actions = []
        for action in actions:
            arr = np.array([False] * 12)
            if action == ['NOOP']:
                self._actions.append(arr)
                continue
            for button in action:
                arr[buttons.index(button)] = True
            self._actions.append(arr)
        self.action_space = gym.spaces.Discrete(len(self._actions))

    def action(self, a): # pylint: disable=W0221
        return self._actions[a].copy()

class RewardScaler(gym.RewardWrapper):
    """
    Bring rewards to a reasonable scale for PPO.

    This is incredibly important and effects performance
    drastically.
    """
    def reward(self, reward):
        return reward * 0.01

class AllowBacktracking(gym.Wrapper):
    """
    Use deltas in max(X) as the reward, rather than deltas
    in X. This way, agents are not discouraged too heavily
    from exploring backwards if there is no way to advance
    head-on in the level.
    """
    def __init__(self, env):
        super(AllowBacktracking, self).__init__(env)
        self._cur_x = 0
        self._max_x = 0

    def reset(self, **kwargs): # pylint: disable=E0202
        self._cur_x = 0
        self._max_x = 0
        return self.env.reset(**kwargs)

    def step(self, action): # pylint: disable=E0202
        obs, rew, done, info = self.env.step(action)
        self._cur_x += rew
        rew = max(0, self._cur_x - self._max_x)
        self._max_x = max(self._max_x, self._cur_x)
        return obs, rew, done, info
