#!/usr/bin/env python3
import os
import sys
import time

from generator.gpt2.gpt2_generator import *
from generator.human_dm import *
from play import *
from story.story_manager import *
from story.utils import *

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

# DM-style prompt template for rich fantasy narration
DM_PROMPT_TEMPLATE = (
    "\n[As a masterful Dungeon Master, describe the scene with vivid sensory details. "
    "Use high fantasy style with sights, sounds, and smells. Include dramatic flair and DnD tropes.]\n"
    "What do you do next? \n> You"
)

# Scene frame decorators for DnD narrative style
DM_SCENE_HEADER = "\n" + "=" * 50 + "\n🏰 DUNGEON MASTER\n" + "=" * 50
DM_SCENE_FOOTER = "-" * 50
PLAYER_ACTION_PREFIX = "\n⚔️  YOUR ACTION:"


class AIPlayer:
    def __init__(self, generator):
        self.generator = generator

    def get_action(self, prompt):
        return self.generator.generate_raw(prompt)


def format_dm_output(action):
    """Format the AI-generated action in DnD narrative style."""
    formatted = DM_SCENE_HEADER + "\n\n"
    formatted += action + "\n\n"
    formatted += DM_SCENE_FOOTER
    formatted += PLAYER_ACTION_PREFIX
    return formatted


def play_dm():

    console_print("Initializing AI Dungeon DM Mode")
    console_print("\n🐉 Welcome, brave adventurer! Your tale awaits...\n")
    generator = GPT2Generator(temperature=0.9)

    story_manager = UnconstrainedStoryManager(HumanDM())
    context, prompt = select_game()
    console_print(context + prompt)
    story_manager.start_new_story(prompt, context=context, upload_story=False)

    player = AIPlayer(generator)

    while True:
        action_prompt = story_manager.story_context() + DM_PROMPT_TEMPLATE
        action = player.get_action(action_prompt)
        print("\n******DEBUG FULL ACTION*******")
        print(action)
        print("******END DEBUG******\n")
        action = action.split("\n")[0]
        punc = action.rfind(".")
        if punc > 0:
            action = action[: punc + 1]
        
        # Format the output with DnD narrative style
        formatted_action = format_dm_output(action)
        shown_action = formatted_action + " " + second_to_first_person("You" + action)
        console_print(shown_action)
        story_manager.act(action)


if __name__ == "__main__":
    play_dm()
