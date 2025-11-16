# User Land Configuration

My user land configuration managed with [chezmoi].

## Requirements

* [chezmoi].

[chezmoi]: https://www.chezmoi.io/

## Bootstrap

### One command

```
$ chezmoi init --apply --source ~/config/dotfiles razor-x
```

### Add your public key to GitHub

GitHub will not allow cloning a public repo over SSH unless
the SSH key is attached to an account.
Since this is a new machine, the SSH public key needs to be added to your
GitHub account, and then the repo origin URL may be updated to use SSH.

#### Option A: Login locally

> [!IMPORTANT]
> This requires a GUI with a default web browser and the GitHub CLI.

Login to GitHub with the CLI.

```
$ gh auth login
```

This will open a web browser and prompt you to add the new SSH key to your account.

#### Option B: Use a trusted device

> [!IMPORTANT]
> Since chezmoi has installed the `~/.ssh/authorized_keys` file,
> you can use an authorized device that is already logged into GitHub
> to upload the public key.

From the trusted device, copy over the public key from this device

```
$ scp new-host:.ssh/id_ed25519.pub
$ gh gh ssh-key add id_ed25519.pub
$ rm id_ed25519.pub
```

### Update the remote to SSH

Now that the new public key is added to GitHub,
update the origin to use SSH

```
$ cd ~/config/dotfiles
$ git remote set-url origin git@github.com:razor-x/dotfiles.git
$ git fetch
```

## License

These configuration files are licensed under the MIT license.

## Warranty

This software is provided by the copyright holders and contributors "as is" and
any express or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose are
disclaimed. In no event shall the copyright holder or contributors be liable for
any direct, indirect, incidental, special, exemplary, or consequential damages
(including, but not limited to, procurement of substitute goods or services;
loss of use, data, or profits; or business interruption) however caused and on
any theory of liability, whether in contract, strict liability, or tort
(including negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.
