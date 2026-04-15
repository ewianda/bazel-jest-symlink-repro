import { renderHook } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import React from 'react'
import { useDeleteItem } from './hook'

// This jest.mock forces Jest to resolve and load './store' from the
// symlinked source file's real path. Node's require() follows the symlink
// to the host filesystem and loads React from host node_modules.
// Meanwhile, @testing-library/react loads React from the sandbox node_modules.
// Two React instances → useContext returns null → test crashes.
jest.mock('./store', () => ({
  useAppDispatch: () => jest.fn(),
}))

describe('useDeleteItem', () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  it('should delete an item', async () => {
    const { result } = renderHook(() => useDeleteItem(), { wrapper })

    await result.current.mutateAsync('123')

    expect(result.current.isSuccess).toBe(true)
  })
})
