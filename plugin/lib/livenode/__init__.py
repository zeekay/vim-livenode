from livenode.client import livenodeException, Client
import os
import vim
import json
import socket

client = Client()


def disable_on_failure(f):
    '''
    Catches any livenode errors and disables livenode automatically.
    '''
    def wrapper(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except livenodeException as e:
            vim.command('call livenode#DisableCompletion()')
            print e
        except socket.error as e:
            if e.errno == 61:
                print 'Unable to connect to livenode.'
            else:
                print 'Not connected to livenode.'
    return wrapper


def is_livenode_buffer(buf):
    '''
    Checks if given buffer is livenode's preview window buffer.
    '''
    if buf.name:
        return buf.name.endswith('[livenode]')
    return False


def is_livenode_window(win):
    '''
    Helper function which checks if the given window is livenode's preview window.
    '''
    if win.buffer.name:
        return win.buffer.name.endswith('[livenode]')
    return False


def preview(result):
    '''
    Displays result in livenode's preview window.
    '''

    if getattr(result, 'get', lambda x: None)('error'):
        result = 'Error // %s' % str(result['error'])
    else:
        result = json.dumps(result, sort_keys=True, indent=2)

    if not int(vim.eval('g:livenode_preview_window')):
        print result
        return

    lines = iter(result.splitlines())
    stay_in_window = False

    if is_livenode_buffer(vim.current.buffer):
        # already in livenode buffer, don't leave it
        stay_in_window = True
    elif filter(lambda win: is_livenode_window(win), vim.windows):
        # found window with our buffer open already
        while not is_livenode_buffer(vim.current.buffer):
            vim.command('wincmd w')
    else:
        # create new preview window
        vim.command('pclose')
        vim.command('%s new' % vim.eval('g:livenode_preview_location'))
        vim.command('setlocal buftype=nofile')
        vim.command('setlocal bufhidden=hide')
        vim.command('setlocal nobuflisted')
        vim.command('set previewwindow')
        vim.command('map <buffer> <enter> :livenodeJsEvalLine<cr>')
        vim.command('imap <buffer> <enter> <c-o>:livenodeJsEvalLine<cr>')

        if filter(lambda buf: is_livenode_buffer(buf), vim.buffers):
            # found our buffer
            vim.command('b \[livenode]')
        else:
            vim.command('set ft=javascript')
            vim.command('file [livenode]')
            # replace first line with beginning of response
            vim.current.buffer[0] = next(lines)

    # append response
    for line in lines:
        vim.current.buffer.append(line)
    vim.current.buffer.append('> ')

    # scroll to bottom and in front of cursor
    vim.command('normal Gll')

    if not stay_in_window:
        # return original window
        vim.command('wincmd p')


@disable_on_failure
def connect(host='127.0.0.1', port=1985):
    '''
    Establish a connection to livenode and enable completions if it succeeds,
    or disable them if it fails.
    '''
    client.close()
    client.connect(host=host, port=port)
    vim.command('call livenode#EnableCompletion()')


@disable_on_failure
def list_websocket_clients(host='127.0.0.1', port=1985):
    '''
    Lists connected WebSocket clients.
    '''
    client.close()
    client.connect(host=host, port=port)
    print client.list_websocket_clients()


@disable_on_failure
def set_active_client(query):
    '''
    Switches the active client to the client which matches the query.
    Tries to use index from livenodeList, if that fails, expects query to be a substring of the client identifier.
    '''
    client.set_active_client(query)


@disable_on_failure
def toggle_broadcast():
    '''
    Toggles broadcast on.
    '''
    client.toggle_broadcast()


@disable_on_failure
def reload(bang, file=''):
    '''
    Attempts to reload a given file by sending the modified event to all WebSocket clients.
    '''
    if bang:
        # Force reload
        return client.modified('')

    if not file:
        file = vim.current.buffer.name.replace(os.getcwd(), '')

    client.modified(file)
