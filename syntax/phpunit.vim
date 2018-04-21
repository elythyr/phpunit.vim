highlight def link phpunitFailure Error
highlight def phpunitOk guibg=Green ctermbg=DarkGreen guifg=Black ctermfg=Black
highlight def link phpunitAssertFail ErrorMsg

syntax match phpunitFailure "^FAILURES.*$" display
syntax match phpunitFailure "^not ok.*$" display
syntax match phpunitOk "\c^ok.*$" display
syntax match phpunitAssertFail "^Files asserting.*$" display

" vim: ts=2 sw=2 et fdm=marker
