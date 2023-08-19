import logging

def md_paragraph_parse(md_body: str, header: str) -> str:
    result = ""
    try:
        header_level = header.split(' ')[0]
    except Exception as e:
        logging.error(f"{header} is not Markdown header. Error {e}")
        return result
    i_start = -1
    try:
        for idx, line in enumerate(md_body.splitlines()):
            if i_start != -1:
                if line.split(' ')[0] == header_level:
                    break
                result += f"{line}\n"
            if header in line:
                i_start = idx
    except Exception as e:
        logging.error(f"Can not parse markdown message. Error {e}")
    return result