import tkinter as tk
from tkinter import messagebox, filedialog
import requests
import json
import re
import urllib3
import urllib.parse

urllib3.disable_warnings()

headers = {
    'accept': 'application/json',
    'accept-encoding': 'gzip, deflate, br',
    'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    'cookie': '_octo=GH1.1.329557152.1722407951; _device_id=f38f305520b30d1e6de4ab292e00b7fc; saved_user_sessions=171770425%3AF4Prc1U4__ivY74PHKJYusHcy96E7Gjzy45-cgIwwlZeOGiS; user_session=F4Prc1U4__ivY74PHKJYusHcy96E7Gjzy45-cgIwwlZeOGiS; __Host-user_session_same_site=F4Prc1U4__ivY74PHKJYusHcy96E7Gjzy45-cgIwwlZeOGiS; logged_in=yes; dotcom_user=Ajax-JX; color_mode=%7B%22color_mode%22%3A%22auto%22%2C%22light_theme%22%3A%22light%22%2C%22dark_theme%22%3A%22dark%22%7D; cpu_bucket=xlg; preferred_color_mode=dark; tz=Asia%2FShanghai; _gh_sess=GjlJZ2VNOV0z1Bj6A1wVluI%2FJloZDQs7xHruK95xE2WNwn9TwHJCPMip%2BQHgOuoRm3mG7vqM3zO9ef706%2Fjtb9x4UFf5lw%2BevnAD32Mj1hAx%2BZt8CqGDWtpxaQLsS3wwLG44UmcGkMR5EUNDE4t0sVKCStlo07jjCFRz2S7X6Il9Faae0%2BJfySHBI9DRcJZI2zvPf%2FkHAlf8vTJg3M5%2Fbjn1HUSjJOuLllh3NgcexV3xxRR93q6gx0PcKfok0ZkFl0bMZ7vaT3pK8P7H08Rozv9BqZn5InBbfUxP5%2FsbKdEiFAksgjcWuznt%2FpZyzsmapuK6yERGw2yQRSb84j4%2FRtUKvzYdF4kav8b2dYTQelw3Mjhs%2F%2FsYEpa1h5yXX7TrNTl5tLI%2FytWT98BuAyDhGRBscW8%3D--bo8Xrm6WIw1DEPHn--jEHsWSdD8lBiz6ecoJ6xuQ%3D%3D',
    'if-none-match': 'W/"1358878c4acc25a4bca6e1c2f64b1853"',
    'referer': 'https://github.com/Ajax-JX/Ajax-JX.github.io/new/main/other',
    'sec-ch-ua': '"Chromium";v="112", "Microsoft Edge";v="112", "Not:A-Brand";v="99"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.58',
    'x-github-target': 'dotcom',
    'x-react-router': 'json',
    'x-requested-with': 'XMLHttpRequest'
   }

def get_info(url):
    try:
        response = requests.get(url, headers=headers, verify=False)
        if response.status_code == 200:
            return json.loads(response.text)
        else:
            print(f"Failed to get info. Status code: {response.status_code}")
            print(f"Response content: {response.text}")
            return None
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {e}")
        print(f"Response content: {response.text}")
        return None

def post_file(filename, filecontent):
    info_url = "https://github.com/Ajax-JX/Ajax-JX.github.io/new/main/other"
    a = get_info(info_url)
    if a is None:
        messagebox.showerror("Error", "Failed to get info for posting file.")
        return
    csrf_tokens = a["payload"]["csrf_tokens"]["/Ajax-JX/Ajax-JX.github.io/create/main/other"]["post"]
    commit_oid = a["payload"]["refInfo"]["currentOid"]
    url = "https://github.com/Ajax-JX/Ajax-JX.github.io/create/main/other"
    data = {
        'message': 'Create ' + filename,
        'placeholder_message': 'Create ' + filename,
        'description': '',
        'commit-choice': 'direct',
        'target_branch': 'main',
        'quick_pull': '',
        'guidance_task': '',
        'commit': commit_oid,
        'same_repo': '1',
        'pr': '',
        'content_changed': 'true',
        'authenticity_token': csrf_tokens
    }
    files = {
        'filename': (None, 'other/' + filename),
        'new_filename': (None, 'other/' + filename),
        'value': (None, filecontent)
    }
    response = requests.post(url, data=data, files=files, verify=False, headers=headers).text
    return response

def delete_file(filename):
    if re.search(r'[\u4e00-\u9fff]', filename):
        # 如果包含中文字符 则进行URL编码
        filename = urllib.parse.quote(filename)
    info_url = "https://github.com/Ajax-JX/Ajax-JX.github.io/delete/main/other/"+filename
    a = get_info(info_url)
    if a is None:
        messagebox.showerror("Error", "Failed to get info for deleting file.")
        return
    csrf_tokens = a["payload"]["csrf_tokens"]["/Ajax-JX/Ajax-JX.github.io/blob/main/other/" + filename]["delete"]
    commit_oid = a["payload"]["refInfo"]["currentOid"]
    url = "https://github.com/Ajax-JX/Ajax-JX.github.io/blob/main/other/" + filename
    data = {
        'message': 'Delete other/' + filename,
        'placeholder_message': 'Delete other/' + filename,
        'description': '',
        'commit-choice': 'direct',
        'target_branch': 'main',
        'quick_pull': '',
        'guidance_task': '',
        'commit': commit_oid,
        'same_repo': '1',
        'pr': '',
        '_method': 'delete',
        'authenticity_token': csrf_tokens
    }
    response = requests.post(url, data=data, verify=False, headers=headers).text
    return response

def get_file():
    try:
        list = requests.get("https://github.com/Ajax-JX/Ajax-JX.github.io/tree-commit-info/main/other", verify=False, headers=headers).text
        pattern = r'"([^"]*)":{"oid"'
        matches = re.findall(pattern, list)
        return matches
    except Exception as e:
        print(f"错误的列表: {e}")
        return []

# GUI
class GitHubFileManager(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("GitHubCloud")
        self.geometry("400x300")

        self.file_list = get_file()
        self.listbox = tk.Listbox(self)
        for file in self.file_list:
            self.listbox.insert(tk.END, file)
        self.listbox.pack(pady=20)

        self.delete_button = tk.Button(self, text="删除", command=self.delete_selected_file)
        self.delete_button.pack(side=tk.LEFT, padx=10)

        self.upload_button = tk.Button(self, text="上传", command=self.upload_file)
        self.upload_button.pack(side=tk.RIGHT, padx=10)

    def delete_selected_file(self):
        selection = self.listbox.curselection()
        if selection:
            index = selection[0]
            filename = self.listbox.get(index)
            confirm = messagebox.askyesno("信息", f"是否删除 {filename}?")
            if confirm:
                response = delete_file(filename)
                if response and "success" in response:
                    messagebox.showinfo("Success", f"{filename} 已被删除")
                    self.listbox.delete(index)
                else:
                    messagebox.showerror("Error", "删除文件失败")
        else:
            messagebox.showwarning("Warning", "你还没有选择要删除的文件呢")

    def upload_file(self):
        file_path = filedialog.askopenfilename()
        if file_path:
            with open(file_path, 'r') as file:
                filecontent = file.read()
            filename = file_path.split('/')[-1]
            response = post_file(filename, filecontent)
            if response and "success" in response:
                messagebox.showerror("Error", "上传错误")
            else:
                messagebox.showinfo("Success", f"{filename} 已被上传")
                self.listbox.insert(tk.END, filename)

if __name__ == "__main__":
    app = GitHubFileManager()
    app.mainloop()
