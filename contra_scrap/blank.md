LSTM tests	
	layer norm
	python3 ppo2_contra_baselines_agent.py --game ContraIII-Snes --state level1.1player.easy.100lives --num_env 3 --seed 22264 --scenario_number 3 --stochastic_frame_skip 4 --scale_reward 0.01 --skip_prob 0.25 --scenario scenario_lvl1_lstm1 --time_limit 8000 --stack 0 --network cnn_lnlstm
	not layer norm
	python3 ppo2_contra_baselines_agent.py --game ContraIII-Snes --state level1.1player.easy.100lives --num_env 3 --seed 22264 --scenario_number 3 --stochastic_frame_skip 4 --scale_reward 0.01 --skip_prob 0.25 --scenario scenario_lvl1_lstm1 --time_limit 8000 --stack 0 --network cnn_lstm

