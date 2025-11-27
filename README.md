# User Land Configuration

My user land configuration managed with [chezmoi].

## Requirements

* [chezmoi].

[chezmoi]: https://www.chezmoi.io/

## Bootstrap new machine

```sh
chezmoi init --apply --source ~/config/dotfiles razor-x
```

### Add public key to GitHub

Since this is a new machine, it is assumed to have a new SSH public-private key pair.
The public key needs to be added to the owner's GitHub account,
which will allow chezmoi to populate it into `~/.ssh/authorized_keys`.

#### Option A: Login locally

> [!IMPORTANT]
> This requires a GUI with a default web browser and the GitHub CLI.

Login to GitHub which will open a web browser and then prompt you to add the new SSH key to your account.

```sh
gh auth login
```

#### Option B: Use a trusted device

> [!IMPORTANT]
> Since chezmoi has already installed the `~/.ssh/authorized_keys` file,
> you can use an authorized device that is already logged into GitHub
> to upload the public key.

From the trusted device, copy over the public key to the new machine

```
$ scp new-host:.ssh/id_ed25519.pub
$ gh ssh-key add id_ed25519.pub
$ rm id_ed25519.pub
```

### Update the remote to SSH

GitHub will not allow cloning a public repo over SSH unless the SSH key is attached to an account.
Now that the new public key is added to GitHub, update the origin to use SSH

```sh
cd ~/config/dotfiles \
 && git remote set-url origin git@github.com:razor-x/dotfiles.git \
 && git fetch
```

### Import GPG key

Copy the ASCII armored private key over to the new machine

```
$ scp private.key new-machine:
```

On the new machine, import the key

```
cd ~/ \
  && gpg --import private.key \
  && rm private.key
```

Then trust the key

```
$ gpg --edit-key <email>
gpg> trust
Your decision? 5 (Ultimate trust)
Do you really want to set this key to ultimate trust? (y/N) y
gpg> quit
```

### Add an SSH passphrase

After a new system is setup it may still have an SSH key without a passphrase.
Add a passphrase with

```
ssh-keygen -p -f ~/.ssh/id_ed25519
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
