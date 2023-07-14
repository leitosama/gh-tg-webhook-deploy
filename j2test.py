import requests
import jinja2
import sys

WEBHOOK_DEFS = "https://octokit.github.io/webhooks/payload-examples/api.github.com/index.json"

if __name__ == "__main__":
    templateLoader = jinja2.FileSystemLoader(searchpath="./templates")
    templateEnv = jinja2.Environment(loader=templateLoader)
    errors = []
    for gh_event in requests.get(WEBHOOK_DEFS).json():
        template = None
        try:
            template = templateEnv.get_template(f"{gh_event['name']}.j2")
        except jinja2.exceptions.TemplateNotFound:
            continue
        for example in gh_event['examples']:
            rendered = None
            try:
                rendered = template.render(data=example)
            except jinja2.exceptions.UndefinedError as e:
                errors.append(f"{gh_event['name']}->{example['action']}->{e}")
                continue
            if rendered == "":
                continue
            print(f"{gh_event['name']}->{example['action']}\n{template.render(data=example)}")
    if len(errors)!=0:
        print("Test found errors:")
        for error in errors:
            print(f"* {error}") 
        exit(-1)
